# zed-hvp

Zed extension providing HVP (Hierarchical Verification Plan) language support: syntax
highlighting (via [`tree-sitter-hvp`](../tree-sitter-hvp)), diagnostics, autocompletion,
outline, and folding (via the [`hvp-language-server`](../hvp-language-server) Node-based
language server).

This extension cannot be loaded into a real Zed instance yet — see the blocker below
before assuming this "just works."

## Package layout

```
extension.toml            ← id/name/version, [language_servers.hvp], [grammars.hvp]
Cargo.toml                ← zed_extension_api = "0.7.0"
src/lib.rs                ← Extension impl: language_server_command via
                             zed::npm_install_package + zed::node_binary_path,
                             modeled directly on zed-extensions/emmet's real source
                             (a directly analogous single-language npm-server extension)
languages/hvp/config.toml ← path_suffixes, line_comments, block_comment, grammar = "hvp"
```

## Remaining blocker

`[grammars.hvp]` now points at `tree-sitter-hvp`'s real remote
(`github.com/Zvord/tree-sitter-hvp`, pinned to its current `main` HEAD), so that half is
resolved. The one still open: **`hvp-language-server` is not published to npm.**
`language_server_command` calls `zed::npm_package_latest_version("hvp-language-server")` /
`zed::npm_install_package(...)`, both of which hit the real npm registry at runtime — same
requirement `LSP-hvp/README.md` documents for Sublime. Until `hvp-language-server@0.1.0`
is published, the language server can never actually start, even if the extension loads.

This extension cannot be verified end-to-end in a real Zed instance until that publish
happens.

## Setup (once the blocker above is resolved)

Requires `rustup` (stable) with the `wasm32-wasip2` target — **not** `wasm32-wasip1`;
Zed's own docs (`docs/src/extensions/developing-extensions.md`) state extensions compile
to `wasm32-wasip2` as of the current `zed_extension_api` (0.7.0).

```sh
source $HOME/.cargo/env   # rustc/cargo onto PATH in a fresh shell
cargo build --release --target wasm32-wasip2
```

This is a `cargo`-only build — Zed's own extension host handles packaging (`.zip` with
`extension.toml` + the compiled wasm) when you install a dev extension or publish; there
is no separate Zed CLI wrapper needed for local development.

Then, in Zed: Extensions panel → **Install Dev Extension** → select this directory. Open
`../hvp-language-server/test/fixtures/realistic-sample.hvp` and confirm diagnostics,
completions, outline (`Ctrl+Shift+O`), folding, and real tree-sitter syntax
highlighting. Then submit to `zed-industries/extensions`.

## Verification done so far (no Zed instance available yet)

- `extension.toml`, `Cargo.toml`, `languages/hvp/config.toml` all parse as valid TOML.
- `cargo check --target wasm32-wasip2` and `cargo build --release --target wasm32-wasip2`
  both succeed cleanly, producing a real `target/wasm32-wasip2/release/zed_hvp.wasm`
  (~240 KB). `cargo fmt --check` is clean.
- `extension.toml`'s shape was cross-checked against real Zed extensions: the bundled
  `extensions/html` and `extensions/glsl` in `zed-industries/zed`, and the standalone
  `zed-extensions/emmet` repo (the closest real analog — single language, npm-installed
  LSP server, `--stdio` launch). `src/lib.rs` is modeled directly on
  `zed-extensions/emmet`'s actual `src/lib.rs`.
- The exact `[grammars.<name>]` schema (`repository` + `rev`, with `commit` as a
  deprecated alias) and `[language_servers.<name>]` schema (`languages` array, with
  singular `language` marked "Deprecated in favor of `languages`" in a doc comment) were
  confirmed by reading `crates/extension/src/extension_manifest.rs` directly in the Zed
  source.

**Not yet verifiable, and not attempted:** `zed: install dev extension`, opening a real
`.hvp` file in Zed, actual grammar fetch/build, actual npm install of the language
server, registry submission. All blocked on the two items above.
