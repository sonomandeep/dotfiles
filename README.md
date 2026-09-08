# Dotfiles Bootstrap

One-command setup for a fresh Fedora or macOS machine.

The installer configures Zsh + Oh My Zsh, Starship, Zoxide, Tmux + TPM, Neovim, Lazygit, Lua + LuaRocks, Go, Vite+, Node.js 24, PNPM, and the Pi coding agent.

## Requirements

- Fedora / DNF-based Linux with a regular user that has `sudo`, **or** macOS with [Homebrew](https://brew.sh/) already installed
- A regular user (**do not run as root**)
- Internet connection and `curl`

On macOS, the installer uses Homebrew for base tools and the system Zsh at `/bin/zsh`.

## Quick Install

```bash
curl -fsSL https://mando.sh/install | bash
```

Verbose mode:

```bash
curl -fsSL https://mando.sh/install | bash -s -- --verbose
```

Help:

```bash
curl -fsSL https://mando.sh/install | bash -s -- --help
```

## What the Script Does

- Installs base dependencies using DNF on Fedora or Homebrew on macOS
- Clones this repo into `~/.dotfiles` (or pulls latest if already present)
- Installs Oh My Zsh and its `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `z` plugins
- Installs Vite+ using its official installer, then configures Vite+ managed Node.js 24 and PNPM at the latest release available during installation
- Installs Pi globally through Vite+ and reconciles its declared extensions
- Creates symlinks:
  - `~/.zshrc` -> `~/.dotfiles/zsh/.zshrc`
  - `~/.config/nvim` -> `~/.dotfiles/nvim`
  - `~/.config/tmux` -> `~/.dotfiles/tmux`
  - `~/.config/starship.toml` -> `~/.dotfiles/starship.toml`
  - `~/.pi/agent/AGENTS.md` -> `~/.dotfiles/pi/AGENTS.md`
  - `~/.pi/agent/settings.json` -> `~/.dotfiles/pi/settings.json`

An existing target is backed up as `<target>.bak` before replacement; correct symlinks are retained. In particular, an existing `~/.zshrc` is backed up as `~/.zshrc.bak`.

## Important Notes

- `~/.dotfiles` is the canonical Git checkout; `~/.config` is not expected to be a Git checkout.
- The versioned Zsh configuration loads Vite+ from either its XDG layout or its legacy layout, and guards Starship and Zoxide when absent.
- Vite+ is currently beta. PNPM uses the `latest` release resolved when the installer runs, so this setup is intentionally not fully reproducible over time.
- Sesh, Bun, OpenCode, and Fastfetch are intentionally not installed or configured by the managed Zsh setup.
- Pi configuration is tracked in `~/.dotfiles/pi`; credentials, sessions, package files, and Herdr's generated `~/.pi/agent/extensions/herdr-agent-state.ts` remain machine-local. The installer never manages `~/.pi/agent/extensions` or installs Herdr.

## After Installation

1. Start a new shell session or run `exec zsh`.
2. Open tmux and press `<prefix> + I` to install TPM plugins.
3. Open Neovim (`nvim`) to trigger first-time plugin setup.
4. Start Pi and authenticate on this machine:

   ```bash
   pi
   # then run /login
   ```

## Troubleshooting

- Re-run with `--verbose` for full output.
- On macOS, install Homebrew before running this script.
- If changing the default shell fails, run:

  ```bash
  chsh -s "$(command -v zsh)" "$USER"
  ```

- If dotfiles pull fails due to local changes, check `~/.dotfiles` status and retry.
