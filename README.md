# Development Environment Bootstrap

A macOS bootstrap that installs the development toolchain, clones this repository into **`~/dotfiles`**, and links its configurations. Run as your regular user; system authorization may be requested for Homebrew and Apple's developer tools.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/sonomandeep/dotfiles/main/install.sh | bash
```

Preview the installation plan:

```bash
curl -fsSL https://raw.githubusercontent.com/sonomandeep/dotfiles/main/install.sh | bash -s -- --dry-run
```

From an existing local checkout:

```bash
DOTFILES_DIR="$PWD" ./install.sh --dry-run
DOTFILES_DIR="$PWD" ./install.sh
```

The remote command uses the version published on GitHub. Commit and push local changes to make them available through that command.

## What it does

- Installs missing Homebrew, Oh My Zsh and Vite+ using their official installers.
- Sets up Apple's developer tools and missing native tools: Git, curl, unzip, Zsh, Lua, LuaRocks, CMake, pkg-config, Neovim, Tree-sitter CLI, Lazygit, Starship, ripgrep, fd, fzf and Zoxide.
- Manages Node.js and pnpm through Vite+. Reuses a compatible installed Node.js (>=22.19), or installs Node.js 24. Reuses installed pnpm, or installs the latest release.
- Installs missing Pi and Codex CLIs, TypeScript 6 SDK and TypeScript/Astro/Tailwind language servers as Vite+ global packages.
- Sets up the Zsh plugins Git, autosuggestions and syntax highlighting.
- Links the repository configurations and enables Starship, Zoxide, toolchain PATH entries, `EDITOR=nvim` and `VISUAL=nvim`.
- Sets Zsh as the login shell.

Existing tools and Vite+ defaults are reused. A new Vite+ installation gets defaults for the installed Node.js and pnpm versions.

## Linked configurations

| Source in the repository | Destination |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `starship.toml` | `~/.config/starship.toml` |
| `nvim/` | `~/.config/nvim` |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `lazygit/config.yml` | `~/Library/Application Support/lazygit/config.yml` |

Neovim uses a minimal manual configuration with native LSP/completion and `vim.pack`. Its five plugins are locked in `nvim/nvim-pack-lock.json`: `fzf-lua` (search), `conform.nvim` (project-aware formatting), `nvim-ts-autotag` (tag automation), `gitsigns.nvim` (Git hunks), and `nvim-treesitter` (parsers/queries shared by native highlighting and Autotag). Tree-sitter highlighting is enabled for HTML, JavaScript, TypeScript, JSX/TSX, Astro and CSS; custom folding, indentation and additional text objects are not configured. Lazygit opens in a native terminal; LazyVim and lazy.nvim are no longer used.

The configuration targets Neovim 0.13 nightly and also works on 0.12. The installer reuses existing Neovim or installs Homebrew stable; it does not silently switch to a prerelease. See [`nvim/README.md`](nvim/README.md) for the explicit nightly install, keys, Vite+/Oxlint integration and optional Go support.

Machine-specific shell additions can go in `${ZDOTDIR:-$HOME}/.zshrc.local`, which Zsh loads last.

## Reruns and backups

An existing checkout is reused with local changes preserved. Correct symlinks are kept; conflicting configurations are moved to `<destination>.backup-<timestamp>.<pid>` before linking.

To restore a previous configuration, remove the new symlink and move its backup back to the original path.

To update the checkout:

```bash
git -C ~/dotfiles pull --ff-only
```

## Custom paths

| Variable | Default |
|---|---|
| `DOTFILES_DIR` | `$HOME/dotfiles` |
| `DOTFILES_REPO` | `https://github.com/sonomandeep/dotfiles.git` |
| `DOTFILES_BRANCH` | `main` |
| `XDG_CONFIG_HOME` | `$HOME/.config` |
| `ZDOTDIR` | `$HOME` |

Use absolute local paths. `DOTFILES_REPO` and `DOTFILES_BRANCH` select the source for new clones. `XDG_CONFIG_HOME` and `ZDOTDIR` select the configuration destinations.

The installer also respects `ZSH`, `ZSH_CUSTOM`, `VP_HOME` and `VP_BIN_DIR`. Keep custom path variables available in subsequent shells.

## After installation

1. Open a new terminal session, or run `exec zsh -l`.
2. Open `nvim` to install its plugins and compile the shared highlighting/Autotag parsers on first launch. In projects, run `vp install` first; formatting/linting follow project tooling rather than global formatter defaults.
3. Authenticate Pi with `/login` and Codex with `codex login` when needed.

## Validation

```bash
bash -n install.sh
zsh -n zsh/.zshrc
DOTFILES_DIR="$PWD" ./install.sh --dry-run
bash nvim/tests/run.sh
```
