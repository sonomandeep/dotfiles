# Development Environment Bootstrap

A macOS bootstrap that installs the toolchain, clones this repository into **`~/dotfiles`**, and links its configurations. Run as your regular user, not with `sudo`.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/sonomandeep/dotfiles/main/install.sh | bash
```

Preview without installing, cloning, or changing local files:

```bash
curl -fsSL https://raw.githubusercontent.com/sonomandeep/dotfiles/main/install.sh | bash -s -- --dry-run
```

The remote command uses the files published on GitHub. Local installer/config changes must be committed and pushed before the remote command can use them.

For an existing local checkout:

```bash
DOTFILES_DIR="$PWD" ./install.sh --dry-run
DOTFILES_DIR="$PWD" ./install.sh
```

Otherwise, executing a local copy of the installer still targets `~/dotfiles` by default. There is no dependency on the installer's location or the working directory, so piping it from `curl` is supported.

## What gets prepared

- Homebrew, Oh My Zsh and Vite+, through their official installers if missing.
- Apple's developer tools when needed. macOS approval or an administrator password may be necessary; the script cannot bypass system authorization.
- Git, curl, unzip, Zsh, Lua, LuaRocks, CMake, pkg-config, Neovim, Lazygit, Starship, ripgrep, fd, fzf and Zoxide. Homebrew resolves native dependencies; Apple's tools supply the C compiler and make.
- Node.js and pnpm exclusively through Vite+. A compatible installed Node.js (>=22.19) is reused; otherwise Node.js 24 is installed. pnpm is reused when available, otherwise its current latest release is installed.
- Missing Pi and Codex CLI installations through `vp install --global`, without dependency lifecycle scripts.
- Zsh plugins: Git, autosuggestions and syntax highlighting.
- Linked shell configuration activating Oh My Zsh, Starship, Zoxide, PATH, `EDITOR=nvim` and `VISUAL=nvim`.
- Zsh as the login shell, if not already selected.

Existing tools are not explicitly upgraded. An existing Vite+ setup keeps its defaults; a newly bootstrapped Vite+ gets defaults for the installed Node/pnpm versions. Missing packages are resolved at installation time, so this is not a fully version-pinned environment.

## Repository and configuration layout

```text
~/dotfiles/
├── install.sh
├── zsh/.zshrc
├── starship.toml
├── nvim/
└── lazygit/config.yml
```

| Destination | Source in the checkout |
|---|---|
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.config/starship.toml` | `starship.toml` |
| `~/.config/nvim` | `nvim/` |
| `~/.config/lazygit/config.yml` | `lazygit/config.yml` |
| `~/Library/Application Support/lazygit/config.yml` | `lazygit/config.yml` |

`XDG_CONFIG_HOME` replaces `~/.config` when set; `ZDOTDIR` replaces `~` for `.zshrc`. Lazygit's macOS default file is also linked so applications launched outside this Zsh environment use the same configuration. Only config files/directories are linked, not Lazygit's runtime-state directory.

Neovim uses the existing versioned configuration, including its plugin lockfile. Plugins are bootstrapped on its first launch. The installer does not generate or synchronize color palettes; appearance belongs to the configuration files.

Machine-specific shell additions can go in `${ZDOTDIR:-$HOME}/.zshrc.local`, loaded last. The installer does not create, replace or version that file.

## Safe reruns and backups

- A missing checkout is cloned from the configured URL/branch.
- An existing checkout is reused **without `git pull`, reset, clean, or stash**. Local edits are preserved. Update it explicitly when desired:

  ```bash
  git -C ~/dotfiles pull --ff-only
  ```

- A destination directory that is not a Git checkout is rejected, not overwritten.
- A correct symlink is retained without a new backup.
- Conflicting files, directories and symlinks are moved to a sibling named `<destination>.backup-<timestamp>.<pid>`. Existing symlink targets are not overwritten by link replacement.
- Before an official bootstrap can append to an existing `.zshrc`, the installer backs it up and detaches its symlink. It links the canonical file only after the bootstrap finishes. Official installers may separately add their own PATH integration to other shell files.
- Partial Oh My Zsh/plugin installations are rejected with an explicit error rather than overwritten.
- Missing source configs cause an error; broken config links are never deliberately created.

To restore a previous configuration, remove the new symlink and move the corresponding backup back to its original name. If a bootstrap produced an intermediate backup too, choose the earliest backup from that run to restore the original configuration.

## Overrides

```bash
curl -fsSL https://raw.githubusercontent.com/sonomandeep/dotfiles/main/install.sh \
  | DOTFILES_DIR="$HOME/dev/dotfiles" bash
```

| Variable | Default |
|---|---|
| `DOTFILES_DIR` | `$HOME/dotfiles` |
| `DOTFILES_REPO` | `https://github.com/sonomandeep/dotfiles.git` |
| `DOTFILES_BRANCH` | `main` |
| `XDG_CONFIG_HOME` | `$HOME/.config` |
| `ZDOTDIR` | `$HOME` |

Use absolute local paths. `DOTFILES_REPO` and `DOTFILES_BRANCH` affect a new clone, not an existing checkout. `ZSH`, `ZSH_CUSTOM`, `VP_HOME` and `VP_BIN_DIR` are also respected where applicable. Custom directory environment variables must remain available in subsequent shells to keep using those locations.

The previous `~/.dotfiles` checkout is not migrated or removed automatically. Existing runtime links may point there; they are backed up and replaced by links into `~/dotfiles` when the new installer runs.

## What stays local

The installer does **not** link or overwrite Pi/Codex settings, provider credentials, sessions, project-trust lists, hooks or MCP configuration. In particular, the older `pi/settings.json` and `pi/AGENTS.md` files still in this repository are **not applied** by this installer. It does not install Rex, its agent skill, Tmux, Herdr or additional language runtimes such as Go.

After installation:

1. Open a new Rex session, or run `exec zsh -l`.
2. Open `nvim` to bootstrap its plugins.
3. Authenticate Pi with `/login` and Codex with `codex login` when needed.

## Validation

```bash
bash -n install.sh
zsh -n zsh/.zshrc
DOTFILES_DIR="$PWD" ./install.sh --dry-run
```
