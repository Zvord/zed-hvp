# zed-hvp — developer map

## Architecture

```
extension.toml            ← id "hvp", [language_servers.hvp] (languages = ["HVP"]),
                             [grammars.hvp] (repository + rev — placeholder, see below)
Cargo.toml                ← zed_extension_api = "0.7.0" (current crates.io max version,
                             compatible with Zed 0.192.x per crates/extension_api/README.md)
src/lib.rs                ← the entire extension: HvpExtension { did_find_server: bool },
                             language_server_command() resolves/installs
                             hvp-language-server via npm and launches it with node + --stdio
languages/hvp/config.toml ← name "HVP", grammar = "hvp", path_suffixes ["hvp"],
                             line_comments ["// "], block_comment ["/*", "*/"], brackets
```

`src/lib.rs` is modeled directly on
[`zed-extensions/emmet`](https://github.com/zed-extensions/emmet)'s `src/lib.rs`. That
extension is the closest real-world analog to this one: single language, one
npm-installed LSP server, launched with `node <script> --stdio`, no `worktree.which()`
PATH-search fallback (unlike `extensions/html` in the main Zed repo, which also checks
for a system-installed binary first — HVP's server has no such fallback path, so that
complexity was left out).

The pattern: `server_script_path()` checks whether
`node_modules/hvp-language-server/bin/hvp-language-server.js` already exists at the
correct version (via `zed::npm_package_latest_version` /
`zed::npm_package_installed_version`), calls `zed::npm_install_package(...)` if not, and
`language_server_command()` returns `zed::Command { command: zed::node_binary_path()?,
args: [<absolute path to server_path>, "--stdio"], env: {} }`.

## API usage, grounded in real Zed source

Every non-obvious piece of this extension's shape was checked against real Zed source,
not assumed:

- **`zed::npm_install_package` / `zed::npm_package_latest_version` /
  `zed::npm_package_installed_version` / `zed::node_binary_path` exact usage** — modeled
  on `zed-extensions/emmet/src/lib.rs` and `zed-industries/zed`'s bundled
  `extensions/html/src/html.rs`.
- **`Extension::language_server_command` signature** —
  `fn language_server_command(&mut self, language_server_id: &LanguageServerId, worktree: &Worktree) -> Result<Command>`,
  confirmed both from `docs.rs/zed_extension_api`'s source view and from the two real
  extensions above.
- **`[grammars.<name>]` schema** — `repository` (required) + `rev` (required, git commit
  SHA), confirmed in two independent ways: (1) `docs/src/extensions/languages.md`'s
  prose and worked example (`[grammars.gleam]` with `repository`/`rev`), and (2) reading
  `crates/extension/src/extension_manifest.rs`'s `GrammarManifestEntry` struct directly
  — `pub rev: String` with `#[serde(alias = "commit")]`, i.e. `commit` (which the
  bundled `extensions/html/extension.toml` happens to still use) is a deprecated alias,
  `rev` is the current canonical field. This extension uses `rev`.
- **`[language_servers.<name>]` schema — `languages` (plural array), not `language`.**
  Two real extension.toml examples disagreed on the surface (`extensions/html` uses
  singular `language = "HTML"`; `zed-extensions/emmet` uses plural
  `languages = [...]`) — resolved by reading `LanguageServerManifestEntry` in
  `extension_manifest.rs` directly: `language: Option<LanguageName>` is doc-commented
  `"Deprecated in favor of `languages`."`. `extensions/html` is simply using the older,
  still-supported form. This extension uses `languages = ["HVP"]`, the current one.
- **Build target is `wasm32-wasip2`, not `wasm32-wasip1`.**
  `docs/src/extensions/developing-extensions.md`'s current text is explicit: `"Zed uses
  the wasm32-wasip2 Rust target to compile extensions."`
- **`block_comment`'s TOML shape** — either the old two-element array
  (`block_comment = ["a", "b"]`, defaults `prefix = ""`, `tab_size = 0`) or the newer
  `{ start, prefix, end, tab_size }` table both parse into the same
  `BlockCommentConfig`, confirmed by reading `crates/language/src/language.rs`'s own
  unit tests for `LanguageConfig` deserialization. This extension uses the plain array
  form (`["/*", "*/"]`, matching `vscode-hvp/language-configuration.json`'s
  `blockComment` values exactly) since HVP has no documented block-comment continuation
  convention worth inventing a `prefix`/`tab_size` for.

## Two things to resolve before this can load in a real Zed instance

1. **`extension.toml`'s `[grammars.hvp]` is a placeholder.** `repository =
   "https://github.com/<your-username>/tree-sitter-hvp"` — `tree-sitter-hvp` has no git
   remote configured yet (see `../tree-sitter-hvp/README.md`), so this URL resolves to
   nothing. `rev = "c2590672fa89828edcae00ad47765e5f3885879e"` is a real commit SHA —
   only `repository` needs fixing once the grammar repo is pushed somewhere real, and
   `rev` should be bumped too if it has moved on by then.
2. **`hvp-language-server` is not on npm.** Same requirement `LSP-hvp` documents — see
   `../LSP-hvp/CLAUDE.md`'s "npm-publish requirement" section. `zed::npm_install_package`
   and `zed::npm_package_latest_version` both hit the real npm registry; both calls 404
   until `hvp-language-server@0.1.0` is published.

Neither is workable around locally the way `vscode-hvp`'s `file:../hvp-language-server`
dependency is — Zed's extension host resolves both the grammar repository and the npm
package against the real internet at install/run time, not against a local checkout.

## Verification done

- All three TOML files (`extension.toml`, `Cargo.toml`, `languages/hvp/config.toml`)
  parse as valid TOML (Python `tomllib`).
- `cargo check --target wasm32-wasip2` and `cargo build --release --target
  wasm32-wasip2` both succeed cleanly; the release build produces a real
  `target/wasm32-wasip2/release/zed_hvp.wasm` (~240 KB, confirmed via `file` as a valid
  WebAssembly binary module). `cargo fmt --check` is clean (no diff).
- `extension.toml` cross-checked structurally against `extensions/html/extension.toml`
  and `extensions/glsl/extension.toml` (bundled in `zed-industries/zed`) and
  `zed-extensions/emmet/extension.toml` (standalone, real, published) — same top-level
  keys (`id`, `name`, `description`, `version`, `schema_version`, `authors`,
  `repository`), same `[language_servers.<name>]` / `[grammars.<name>]` shapes.

**Not yet done, blocked on the two items above:** `zed: install dev extension` in a
real Zed instance, opening `../hvp-language-server/test/fixtures/realistic-sample.hvp`
and confirming diagnostics/completion/outline/folding/highlighting, actual grammar
fetch-and-build by Zed's extension host, actual `npm install` of `hvp-language-server`,
`zed-industries/extensions` registry submission.

## Not this repo's job

Replacing `hvp-language-server/src/core/blockAnalysis.ts`'s regex-based block scanning
with `tree-sitter-hvp`'s real grammar — see `../tree-sitter-hvp/CLAUDE.md`.
