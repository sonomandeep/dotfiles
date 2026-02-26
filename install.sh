#!/bin/bash
# =============================================================================
#  install.sh - Linux environment setup script
#  Installs: zsh + oh-my-zsh + plugins, starship, tmux, neovim
#  Dotfiles: https://github.com/sonomandeep/dotfiles
# =============================================================================

set -euo pipefail

# ── Flags ─────────────────────────────────────────────────────────────────────
VERBOSE=false
for arg in "$@"; do
  case "$arg" in
  --verbose | -v) VERBOSE=true ;;
  --help | -h)
    echo "Usage: $0 [--verbose|-v]"
    echo "  --verbose, -v   Print detailed installation output"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg"
    exit 1
    ;;
  esac
done

# ── Colors & Logging ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
info() { $VERBOSE && echo -e "${BLUE}[→]${NC} $1" || true; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() {
  echo -e "${RED}[✗]${NC} $1"
  exit 1
}
section() { echo -e "\n${BOLD}${BLUE}══ $1 ══${NC}"; }

# Run a command silently unless --verbose is set
quiet() { $VERBOSE && "$@" || "$@" &>/dev/null; }

# ── Sanity Checks ─────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && err "Do not run this script as root. Use a regular user with sudo privileges."
command -v sudo &>/dev/null || err "sudo is required but not installed."
command -v dnf &>/dev/null || err "This script is intended for Fedora/DNF-based systems."

DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/sonomandeep/dotfiles"

# ── Helper: symlink with backup ────────────────────────────────────────────────
symlink() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      log "Symlink already correct: $dst"
      return
    fi
    warn "Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -sf "$src" "$dst"
  log "Linked: $dst → $src"
}

# ── Helper: check if command exists ───────────────────────────────────────────
is_installed() { command -v "$1" &>/dev/null; }

# =============================================================================
#  1. SYSTEM UPDATE & BASE DEPS
# =============================================================================
section "System update & base dependencies"

info "Updating package list..."
quiet sudo dnf check-update || true # check-update exits 100 if updates exist, not an error

info "Installing base dependencies..."
quiet sudo dnf install -y \
  git curl wget unzip tar \
  gcc make \
  util-linux-user ||
  err "Failed to install base dependencies."

log "Base dependencies installed."

# =============================================================================
#  2. DOTFILES
# =============================================================================
section "Dotfiles"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not pull dotfiles (maybe dirty). Continuing."
else
  info "Cloning dotfiles from $DOTFILES_REPO..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || err "Failed to clone dotfiles."
fi

log "Dotfiles ready at $DOTFILES_DIR"

# =============================================================================
#  3. ZSH + OH MY ZSH + PLUGINS
# =============================================================================
section "Zsh + Oh My Zsh + plugins"

# ── Install zsh ───────────────────────────────────────────────────────────────
if ! is_installed zsh; then
  info "Installing zsh..."
  quiet sudo dnf install -y zsh || err "Failed to install zsh."
  log "zsh installed."
else
  log "zsh is already installed."
fi

# ── Install oh-my-zsh ─────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  if $VERBOSE; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || err "Failed to install Oh My Zsh."
  else
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null || err "Failed to install Oh My Zsh."
  fi
  log "Oh My Zsh installed."
else
  log "Oh My Zsh is already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── zsh-syntax-highlighting ───────────────────────────────────────────────────
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  info "Installing zsh-syntax-highlighting..."
  quiet git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ||
    err "Failed to install zsh-syntax-highlighting."
  log "zsh-syntax-highlighting installed."
else
  log "zsh-syntax-highlighting already installed."
fi

# ── zsh-autosuggestions ───────────────────────────────────────────────────────
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  info "Installing zsh-autosuggestions..."
  quiet git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ||
    err "Failed to install zsh-autosuggestions."
  log "zsh-autosuggestions installed."
else
  log "zsh-autosuggestions already installed."
fi

# ── Generate .zshrc ───────────────────────────────────────────────────────────
info "Writing ~/.zshrc..."
cat >"$HOME/.zshrc" <<'EOF'
# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # disabled — using starship

plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    z
    colored-man-pages
)

source "$ZSH/oh-my-zsh.sh"

# ── Starship prompt ───────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias vim="nvim"
alias vi="nvim"
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias grep="grep --color=auto"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
EOF

log "~/.zshrc written."

# ── Set zsh as default shell ──────────────────────────────────────────────────
ZSH_PATH="$(which zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  info "Changing default shell to zsh for user $USER..."
  chsh -s "$ZSH_PATH" "$USER" || err "Failed to change shell. Try running: chsh -s $ZSH_PATH"
  log "Default shell changed to zsh."
else
  log "zsh is already the default shell."
fi

# =============================================================================
#  4. STARSHIP PROMPT
# =============================================================================
section "Starship prompt"

if ! is_installed starship; then
  info "Installing starship..."
  if $VERBOSE; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes || err "Failed to install starship."
  else
    curl -sS https://starship.rs/install.sh | sh -s -- --yes &>/dev/null || err "Failed to install starship."
  fi
  log "Starship installed."
else
  log "Starship is already installed."
fi

# ── Symlink starship.toml ─────────────────────────────────────────────────────
if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
  symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
else
  warn "No starship.toml found in dotfiles. Skipping symlink."
fi

# =============================================================================
#  5. TMUX
# =============================================================================
section "Tmux"

if ! is_installed tmux; then
  info "Installing tmux..."
  quiet sudo dnf install -y tmux || err "Failed to install tmux."
  log "Tmux installed."
else
  log "Tmux is already installed."
fi

# ── Symlink tmux config ───────────────────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/tmux" ]]; then
  symlink "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
else
  warn "No tmux/ directory found in dotfiles. Skipping symlink."
fi

# ── TPM (Tmux Plugin Manager) ─────────────────────────────────────────────────
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  info "Installing TPM (Tmux Plugin Manager)..."
  quiet git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" ||
    err "Failed to install TPM."
  log "TPM installed. Press <prefix>+I inside tmux to install plugins."
else
  log "TPM already installed."
fi

# =============================================================================
#  6. LUA 5.1 & LUAROCKS
# =============================================================================
section "Lua 5.1 & LuaRocks"

if ! rpm -q lua5.1 &>/dev/null; then
  info "Installing Lua 5.1..."
  quiet sudo dnf install -y lua5.1 || err "Failed to install Lua 5.1."
  log "Lua 5.1 installed."
else
  log "Lua 5.1 is already installed."
fi

if ! is_installed luarocks; then
  info "Installing LuaRocks..."
  quiet sudo dnf install -y luarocks || err "Failed to install LuaRocks."
  log "LuaRocks installed."
else
  log "LuaRocks is already installed."
fi

# =============================================================================
#  7. NEOVIM
# =============================================================================
section "Neovim"

NVIM_MIN_VERSION="0.9"

install_neovim() {
  info "Installing Neovim from GitHub releases..."
  local tmp
  tmp=$(mktemp -d)
  local arch
  arch=$(uname -m)

  case "$arch" in
  x86_64) local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" ;;
  aarch64) local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz" ;;
  *) err "Unsupported architecture: $arch" ;;
  esac

  quiet curl -sL "$nvim_url" -o "$tmp/nvim.tar.gz" || err "Failed to download Neovim."
  quiet tar -xzf "$tmp/nvim.tar.gz" -C "$tmp" || err "Failed to extract Neovim."

  sudo rm -rf /opt/nvim
  sudo mv "$tmp"/nvim-linux-* /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

  rm -rf "$tmp"
  log "Neovim installed to /opt/nvim"
}

if is_installed nvim; then
  CURRENT_VERSION=$(nvim --version | head -1 | grep -oP '\d+\.\d+')
  if [[ "$(echo -e "$CURRENT_VERSION\n$NVIM_MIN_VERSION" | sort -V | head -1)" != "$NVIM_MIN_VERSION" ]]; then
    warn "Neovim version $CURRENT_VERSION is below $NVIM_MIN_VERSION. Reinstalling..."
    install_neovim
  else
    log "Neovim $CURRENT_VERSION already installed."
  fi
else
  install_neovim
fi

# ── Symlink nvim config ───────────────────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/nvim" ]]; then
  symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
else
  warn "No nvim/ directory found in dotfiles. Skipping symlink."
fi

# =============================================================================
#  8. LAZYGIT
# =============================================================================
section "Lazygit"

if ! is_installed lazygit; then
  info "Enabling COPR repository for lazygit..."
  quiet sudo dnf copr enable dejan/lazygit -y || err "Failed to enable lazygit COPR repo."

  info "Installing lazygit..."
  quiet sudo dnf install -y lazygit || err "Failed to install lazygit."
  log "Lazygit installed."
else
  log "Lazygit is already installed."
fi

# =============================================================================
#  9. GO
# =============================================================================
section "Go"

if ! is_installed go; then
  info "Installing Go..."
  quiet sudo dnf install -y golang || err "Failed to install Go."
  log "Go installed."
else
  log "Go $(go version | awk '{print $3}') is already installed."
fi

# ── Add GOPATH/bin to .zshrc if not already present ──────────────────────────
if ! grep -q 'GOPATH' "$HOME/.zshrc"; then
  info "Adding GOPATH to ~/.zshrc..."
  cat >>"$HOME/.zshrc" <<'EOF'

# ── Go ────────────────────────────────────────────────────────────────────────
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
EOF
  log "GOPATH added to ~/.zshrc."
fi

# =============================================================================
#  10. VOLTA (Node.js version manager)
# =============================================================================
section "Volta"

if ! is_installed volta; then
  info "Installing Volta..."
  if $VERBOSE; then
    curl -fsSL https://get.volta.sh | bash -s -- --skip-setup || err "Failed to install Volta."
  else
    curl -fsSL https://get.volta.sh | bash -s -- --skip-setup &>/dev/null || err "Failed to install Volta."
  fi
  log "Volta installed."
else
  log "Volta $(volta --version) is already installed."
fi

# ── Add Volta to .zshrc if not already present ───────────────────────────────
if ! grep -q 'VOLTA_HOME' "$HOME/.zshrc"; then
  info "Adding Volta to ~/.zshrc..."
  cat >>"$HOME/.zshrc" <<'EOF'

# ── Volta ─────────────────────────────────────────────────────────────────────
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
EOF
  log "Volta added to ~/.zshrc."
fi

# =============================================================================
#  DONE
# =============================================================================
section "Setup complete!"

echo -e "
${GREEN}${BOLD}Everything is installed and configured.${NC}

  ${BLUE}Next steps:${NC}
  1. Start a new shell session or run:  ${BOLD}exec zsh${NC}
  2. Open tmux and press ${BOLD}<prefix>+I${NC} to install tmux plugins (TPM)
  3. Open neovim (${BOLD}nvim${NC}) — plugins will install automatically on first launch
  4. Install a Node.js version with Volta: ${BOLD}volta install node${NC}

  ${BLUE}Symlinks created:${NC}
  • ~/.config/nvim          → $DOTFILES_DIR/nvim
  • ~/.config/tmux          → $DOTFILES_DIR/tmux
  • ~/.config/starship.toml → $DOTFILES_DIR/starship.toml

  ${BLUE}Installed:${NC}
  zsh + oh-my-zsh, starship, tmux + TPM, neovim, lazygit, go, volta
"
