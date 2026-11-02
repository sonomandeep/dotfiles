# Minimal Neovim

A small, manual configuration targeting **Neovim 0.13 nightly**, also tested on
0.12. No LazyVim, lazy.nvim, Mason, dashboard, file-tree plugin or completion
framework. Normal Vim editing, buffers, splits and native LSP mappings remain
available.

Five focused plugins, managed by `vim.pack`:

- **fzf-lua**: files, project text, buffers, diagnostics and symbols.
- **conform.nvim**: project-aware external formatting, without LSP fallback.
- **nvim-ts-autotag**: automatically close tags and rename paired tags.
- **gitsigns.nvim**: Git change indicators, hunk navigation/preview and blame.
- **nvim-treesitter**: parsers and queries for native syntax highlighting and
  Autotag. No custom indentation, folding or additional text objects.

Lazygit runs in a native terminal tab. The `mando` colorscheme is local; the
statusline, diagnostics, completion, snippets and file explorer (`netrw`) are
built in. Tree-sitter highlighting is enabled for HTML, JavaScript, TypeScript,
JSX/TSX, Astro and CSS, alongside LSP semantic tokens. Other filetypes retain
runtime syntax highlighting.

## Requirements and setup

The root `install.sh` installs missing native tools and web language servers,
but **reuses the installed Neovim and does not silently switch it to a prerelease**.
Its normal Homebrew install uses the stable formula. To explicitly switch to
the development build on macOS:

```sh
brew reinstall --HEAD neovim
nvim --version
```

`--HEAD` tracks development, not a pinned 0.13 build. Keep a known-good version
available if you depend on the editor for daily work. Returning to Homebrew
stable is explicit too: `brew reinstall neovim`.

Dependencies when installing without the root bootstrap:

```sh
brew install neovim git fzf ripgrep fd lazygit tree-sitter-cli
vp install --global --ignore-scripts 'typescript@~6' typescript-language-server \
  @astrojs/language-server @tailwindcss/language-server
```

TypeScript is an external SDK, not a Neovim plugin. Astro currently needs the
JavaScript SDK supplied by TypeScript 6; TypeScript 7 no longer includes
`tsserverlibrary.js`. Workspace-local compatible SDKs take precedence, with a
global fallback that also resolves Vite+'s executable shims. The bootstrap
preserves already installed tools; if your only global TypeScript is 7, install
a compatible SDK explicitly or add one to the project.

Go support is optional:

```sh
brew install go
go install golang.org/x/tools/gopls@latest
```

The repository's Zsh config already adds `$(go env GOPATH)/bin` to PATH. Restart
the shell/editor after installing tools. Missing servers are not launched, and
nothing downloads servers while editing.

On the first launch, `vim.pack` downloads the five plugins at the revisions in
`nvim-pack-lock.json`. This needs Git and network access. No automatic plugin
updates run in the background.

The configuration downloads and compiles the HTML, JavaScript, TypeScript, TSX,
Astro and CSS parsers asynchronously on first launch, including their query dependencies.
This needs `curl`, `tar`, a C compiler (Apple's developer tools) and the native
`tree-sitter` CLI >= 0.26.1 (`tree-sitter-cli` in Homebrew, not the npm package).
Parsers/queries live in Neovim's data directory under `autotag/`, separate from
old LazyVim parsers. Highlighting and tag automation become available when
installation finishes, including in files already open; installation does not
block editing. Astro's embedded TypeScript and CSS use their respective parsers.
Until installation finishes, runtime syntax remains available. Errors can be
inspected with `:TSLog`.

Tag closing (`<div` + `>` → `<div></div>`) and paired renaming on leaving insert
mode work for HTML, JSX/TSX and Astro. This does not add parentheses/quote pairing.
Gitsigns keeps blame text and whole-line highlighting off by default; normal
changes appear only in the sign column. Use its commands for staging/resetting
hunks explicitly; no destructive Git actions are bound to new shortcuts.

## Language support

| Files | Server |
|---|---|
| JavaScript, TypeScript, JSX, TSX | `typescript-language-server` |
| Astro | `astro-ls` |
| Tailwind classes, including `cn`, `clsx`, `cva`, `tw` | `tailwindcss-language-server` |
| Vite+/Oxlint projects | `vp lint --lsp` or standalone `oxlint --lsp` |
| Go | `gopls` |

Next.js and TanStack Start use the TypeScript/React support. Tailwind starts
only for projects declaring `tailwindcss` or having a Tailwind config, including
v4 projects without a JS config. Its server discovers the CSS entrypoints.

Project-local executables are preferred, including those at a workspace
ancestor, then PATH. Root searches stop at the Git boundary. Install project
dependencies with `vp install` before opening the project.

## Formatting and linting

- A `vite-plus` dependency opts the project into **`vp fmt` and `vp lint --lsp`**,
  using the project's Vite+ configuration/defaults.
- Standalone Oxfmt/Oxlint require their dependency or a recognized config:
  `.oxfmtrc.json`, `.oxfmtrc.jsonc`, `oxfmt.config.ts`, `.oxlintrc.json`,
  `.oxlintrc.jsonc` or `oxlint.config.ts`.
- A generic `vite.config.ts` alone does **not** opt a project into formatting.
- Tools run from the detected project root. Nothing installs a formatter or
  silently falls back to Prettier, Biome, ESLint or LSP formatting.
- Go files use `gofmt` only inside a module/workspace (`go.mod`/`go.work`).
- Other files/projects are left untouched. Formatting failures are reported.

Configured formatting runs synchronously before saving, with a two-second
timeout. `:FormatToggle` disables/enables it for the current buffer; manual
formatting remains available. Oxlint provides diagnostics and code actions;
there is no automatic lint-fix-on-save.

Astro formatting also needs the support required by your project-local Oxfmt
version. Current Oxfmt requires `@astrojs/compiler-rs` and its `astro` option;
this config deliberately does not install or enable them for your project.

## Keys

`<leader>` is Space. Everything else follows Neovim's defaults.

| Key | Action |
|---|---|
| `<leader>ff` | Find project files, including hidden files (respecting ignore rules) |
| `<leader>fg` | Search project text |
| `<leader>fb` | Open buffers |
| `<leader>fd` | Workspace diagnostics |
| `<leader>fs` | Document symbols |
| `<leader>e` | Native file explorer |
| `<leader>gg` | Lazygit in a terminal tab; quit Lazygit to return |
| `]c` / `[c` | Next / previous Git hunk (native behavior is preserved in diff windows) |
| `<leader>gh` | Preview the current Git hunk |
| `<leader>gb` | Blame the current line |
| `<leader>cf` | Format with the configured project formatter |
| `jj` in insert mode | Escape |
| `gd` | LSP definition |
| `K` | Hover documentation (native) |
| `grn` / `gra` / `grr` / `gri` / `grt` | Rename / code action / references / implementation / type definition (native) |
| `[d` / `]d` / `<C-w>d` | Previous / next diagnostic / diagnostic float (native) |
| `<C-Space>` in insert mode | Request LSP completion |
| `<C-n>` / `<C-p>` / `<C-y>` / `<C-e>` | Next / previous / accept / dismiss completion (native) |
| `<C-s>` in insert mode | Signature help (native) |

Completion opens automatically for identifiers and server trigger characters.
Enter retains its normal behavior; accept suggestions with `<C-y>`. System
clipboard access remains explicit via `"+y` / `"+p`; Tab is not remapped.

Useful native commands: `:buffers`, `:bnext`, `:bprevious`, `:split`, `:vsplit`,
`:terminal`, `:help`. Leave terminal input with `<C-\><C-n>`.

## Maintenance and troubleshooting

```vim
:lua vim.pack.update()
```

Review the update buffer, `:write` to accept or `:quit` to discard, then restart
Neovim. After updating `nvim-treesitter`, run `:TSUpdate` to align the installed
parsers/queries with its pinned manifest. Commit `nvim-pack-lock.json` after
accepting updates. To synchronize already-installed plugins with a checked-out lockfile:

```vim
:lua vim.pack.update(nil, { target = "lockfile" })
```

Use `:checkhealth vim.lsp`, `:checkhealth fzf-lua`, `:checkhealth nvim-treesitter`,
`:ConformInfo`, `:TSLog`, `:messages` and
`:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))` to investigate issues.
No LazyVim configuration is loaded. Old LazyVim/Mason/LeetCode data on disk is
left untouched; you can archive it separately after checking the new setup.

## Files and tests

- `init.lua`: startup order.
- `lua/config/options.lua`: editor/diagnostic options.
- `lua/config/plugins.lua`: five plugin specs and formatting.
- `lua/config/autotag.lua`: shared parsers, native Tree-sitter highlighting and tag automation.
- `lua/config/git.lua`: Git indicators and buffer-local hunk mappings.
- `lua/config/lsp.lua`: five native LSP configurations and completion.
- `lua/config/project.lua`: roots, local executables and TypeScript SDK lookup.
- `lua/config/keymaps.lua`: small set of utility mappings.
- `lua/config/terminal.lua`: Lazygit terminal lifecycle.

Run the smoke tests from the repository root:

```sh
bash nvim/tests/run.sh
NVIM_BIN=/path/to/nightly/bin/nvim bash nvim/tests/run.sh
```

Tests copy the config into isolated XDG directories, install the locked plugins
and compile the parsers (network and the build tools above required). They check
startup, roots, formatter gating/behavior, SDK lookup, LSP gating, Lazygit,
HTML/JSX/TSX/Astro tag closing/renaming and Git hunks in a temporary repository.
They also check Tree-sitter highlighting, Astro's embedded languages, activation
in files opened before parser installation, and unchanged indentation/folding.
Temporary data is removed afterwards; no user config, parsers or Git repositories
are modified.
