# zed-hvp

Zed extension for HVP (Hierarchical Verification Plan),
the plan language used by Synopsys Verification Planner.
Adds syntax highlighting, diagnostics, autocompletion, document outline, and code folding for `.hvp` files.

## HVP

Hierarchical verification plan is a text description for verification plans used by Synopsys EDA tools.
It allows arbitrary nesting of features, multiple measures for each feature (such as test status, coverage percentage, etc), and multiple sources for each measure.

Although Synopsys provides a GUI to edit HVP,
being a text format, it is quite often more natural to edit it in an editor.
This extension provides basic features to facilitate this.

## Features

- **Syntax highlighting** — via the [`tree-sitter-hvp`](https://github.com/Zvord/tree-sitter-hvp) grammar.
- **Diagnostics** — flags mismatched/unclosed/orphaned block keywords (`plan`/`endplan`, `feature`/`endfeature`, `metric`/`endmetric`, `measure`/`endmeasure`, `override`/`endoverride`, `filter`/`endfilter`, `until`/`enduntil`).
- **Autocompletion** — keyword and snippet completion for block openers, attribute/annotation types, and built-in metric names.
- **Outline / Go to Symbol** — jump between `plan`/`feature`/`metric`/`measure`/`override`/`filter`/`subplan` declarations.
- **Folding** — for every block pair above.

Diagnostics, completion, and outline are served by [`hvp-language-server`](https://github.com/Zvord/hvp-language-server), a standalone LSP server published on npm.
Zed downloads and runs it using its own managed Node.js runtime, so no local Node install is required.

## Installation

From Zed: **Extensions** panel → search **HVP** → Install.

## For contributors and reviewers

This extension is a thin wrapper, not where the language logic lives:

```
extension.toml            ← [language_servers.hvp] (name/languages), [grammars.hvp]
                             (repository + rev, pinned to a tree-sitter-hvp commit)
src/lib.rs                ← resolves/installs hvp-language-server via npm at runtime
                             and launches it with Zed's managed Node binary, --stdio
languages/hvp/config.toml ← path_suffixes, comment/bracket config
languages/hvp/highlights.scm ← syntax highlighting query (copied from tree-sitter-hvp)
languages/hvp/outline.scm ← Outline-panel query
```

The actual grammar lives in `tree-sitter-hvp`,
and the actual completion/diagnostics logic lives in `hvp-language-server`.
Both are separate, independently versioned repositories this extension just wires together.

### Building from source

```sh
rustup target add wasm32-wasip2
cargo build --release --target wasm32-wasip2
```

To try a local checkout in Zed without publishing:
**Extensions** panel → **Install Dev Extension** → select this directory.

## License

MIT — see [`LICENSE`](./LICENSE).
