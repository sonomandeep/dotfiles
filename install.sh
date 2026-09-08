#!/bin/bash
# =============================================================================
#  install.sh - Fedora and macOS environment setup script
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
quiet() {
  if $VERBOSE; then
    "$@"
  else
    "$@" &>/dev/null
  fi
}

# ── Sanity Checks ─────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && err "Do not run this script as root. Use a regular user with sudo privileges."
OS="$(uname -s)"
case "$OS" in
Linux)
  command -v sudo &>/dev/null || err "sudo is required but not installed."
  command -v dnf &>/dev/null || err "This script is intended for Fedora/DNF-based systems."
  PACKAGE_MANAGER="dnf"
  ;;
Darwin)
  command -v brew &>/dev/null || err "Homebrew is required on macOS. Install Homebrew first, then re-run this script."
  PACKAGE_MANAGER="brew"
  ;;
*) err "Unsupported operating system: $OS. This script supports Fedora and macOS." ;;
esac

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

if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
  info "Updating package list..."
  quiet sudo dnf check-update || true # check-update exits 100 if updates exist, not an error

  info "Installing base dependencies..."
  quiet sudo dnf install -y \
    git curl wget unzip tar \
    gcc make \
    util-linux-user ||
    err "Failed to install base dependencies."
else
  info "Installing Homebrew dependencies..."
  quiet brew install \
    git curl wget unzip gnu-tar \
    gcc make tmux lua luarocks neovim go lazygit ||
    err "Failed to install Homebrew dependencies."
fi

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
if [[ "$OS" == "Darwin" ]]; then
  log "Using the macOS system zsh at /bin/zsh."
elif ! is_installed zsh; then
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

# ── Vite+ (Node.js and package-manager manager) ─────────────────────────────
# Install before linking ~/.zshrc: the official installer may update shell files.
section "Vite+"

install_vite_plus() (
  local vite_plus_zdotdir
  vite_plus_zdotdir="$(mktemp -d "${TMPDIR:-/tmp}/vite-plus-zdotdir.XXXXXX")" || exit 1
  trap 'rm -rf -- "$vite_plus_zdotdir"' EXIT

  if $VERBOSE; then
    curl -fsSL https://vite.plus | ZDOTDIR="$vite_plus_zdotdir" VP_NODE_MANAGER=yes bash
  else
    curl -fsSL https://vite.plus | ZDOTDIR="$vite_plus_zdotdir" VP_NODE_MANAGER=yes bash &>/dev/null
  fi
)

if ! is_installed vp; then
  info "Installing Vite+..."
  install_vite_plus || err "Failed to install Vite+."
  log "Vite+ installed."
else
  log "Vite+ is already installed."
fi

# Make Vite+ available to this installer for its XDG and legacy layouts.
VITE_PLUS_XDG_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env"
VITE_PLUS_LEGACY_ENV="$HOME/.vite-plus/env"
if [[ -f "$VITE_PLUS_XDG_ENV" ]]; then
  source "$VITE_PLUS_XDG_ENV"
elif [[ -f "$VITE_PLUS_LEGACY_ENV" ]]; then
  source "$VITE_PLUS_LEGACY_ENV"
fi
is_installed vp || err "Vite+ is not available after installation."

info "Configuring Vite+ for Node.js 24 and the latest PNPM..."
quiet vp env install node@24 || err "Failed to install Node.js 24 through Vite+."
quiet vp env install pnpm@latest || err "Failed to install PNPM through Vite+."
quiet vp env default node@24 || err "Failed to set the Vite+ Node.js default."
quiet vp env default pnpm@latest || err "Failed to set the Vite+ PNPM default."
log "Vite+ Node.js 24 and PNPM configured."

# ── Link versioned zsh configuration ──────────────────────────────────────────
if [[ -f "$DOTFILES_DIR/zsh/.zshrc" ]]; then
  symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
else
  err "Missing Zsh configuration: $DOTFILES_DIR/zsh/.zshrc"
fi

# ── Set zsh as default shell ──────────────────────────────────────────────────
if [[ "$OS" == "Darwin" && -x /bin/zsh ]]; then
  ZSH_PATH="/bin/zsh"
else
  ZSH_PATH="$(command -v zsh)"
fi
if [[ "$OS" == "Darwin" ]]; then
  CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
else
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
fi

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

# ── Zoxide ────────────────────────────────────────────────────────────────────
if ! is_installed zoxide; then
  info "Installing zoxide..."
  if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
    quiet sudo dnf install -y zoxide || err "Failed to install zoxide."
  else
    quiet brew install zoxide || err "Failed to install zoxide."
  fi
  log "Zoxide installed."
else
  log "Zoxide is already installed."
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
  if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
    quiet sudo dnf install -y tmux || err "Failed to install tmux."
  else
    quiet brew install tmux || err "Failed to install tmux."
  fi
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
#  6. LUA & LUAROCKS
# =============================================================================
if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
  section "Lua (compat-lua 5.1) & LuaRocks"
else
  section "Lua & LuaRocks"
fi

if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
  if ! rpm -q compat-lua &>/dev/null; then
    info "Installing compat-lua (Lua 5.1)..."
    quiet sudo dnf install -y compat-lua compat-lua-devel || err "Failed to install compat-lua."
    log "compat-lua (Lua 5.1) installed."
  else
    log "compat-lua (Lua 5.1) is already installed."
  fi
else
  log "Lua is managed by Homebrew."
fi

if ! is_installed luarocks; then
  info "Installing LuaRocks..."
  if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
    quiet sudo dnf install -y luarocks || err "Failed to install LuaRocks."
  else
    quiet brew install luarocks || err "Failed to install LuaRocks."
  fi
  log "LuaRocks installed."
else
  log "LuaRocks is already installed."
fi

# =============================================================================
#  7. NEOVIM
# =============================================================================
section "Neovim"

NVIM_MIN_VERSION="0.10"

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

version_at_least() {
  local current="$1" minimum="$2"
  local current_major current_minor minimum_major minimum_minor
  IFS=. read -r current_major current_minor <<<"$current"
  IFS=. read -r minimum_major minimum_minor <<<"$minimum"
  ((current_major > minimum_major || (current_major == minimum_major && current_minor >= minimum_minor)))
}

if is_installed nvim; then
  CURRENT_VERSION=$(nvim --version | awk 'NR == 1 { sub(/^NVIM v?/, ""); split($1, version, "."); print version[1] "." version[2] }')
  if ! version_at_least "$CURRENT_VERSION" "$NVIM_MIN_VERSION"; then
    warn "Neovim version $CURRENT_VERSION is below $NVIM_MIN_VERSION. Reinstalling..."
    if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
      install_neovim
    else
      quiet brew upgrade neovim || quiet brew install neovim || err "Failed to upgrade Neovim."
    fi
  else
    log "Neovim $CURRENT_VERSION already installed."
  fi
else
  if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
    install_neovim
  else
    quiet brew install neovim || err "Failed to install Neovim."
    log "Neovim installed via Homebrew."
  fi
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

install_lazygit_via_go() {
  info "Installing lazygit via go install..."
  GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$GOPATH/bin:$PATH"
  quiet go install github.com/jesseduffield/lazygit@latest || err "Failed to install lazygit via go install."
  log "Lazygit installed via go install."
}

install_lazygit_via_copr() {
  info "Enabling COPR repository for lazygit (dejan/lazygit)..."
  if quiet sudo dnf copr enable dejan/lazygit -y && quiet sudo dnf install -y lazygit; then
    log "Lazygit installed via COPR."
    return 0
  else
    warn "COPR install failed, falling back to go install..."
    return 1
  fi
}

if ! is_installed lazygit; then
  if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
    info "Installing lazygit with Homebrew..."
    quiet brew install lazygit || err "Failed to install lazygit."
    log "Lazygit installed via Homebrew."
  elif is_installed go; then
    install_lazygit_via_go
  else
    install_lazygit_via_copr || warn "Could not install lazygit now. Re-run the script after Go is installed, or run: go install github.com/jesseduffield/lazygit@latest"
  fi
else
  log "Lazygit is already installed."
fi

# =============================================================================
#  9. GO
# =============================================================================
section "Go"

if ! is_installed go; then
  info "Installing Go..."
  if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
    quiet sudo dnf install -y golang || err "Failed to install Go."
  else
    quiet brew install go || err "Failed to install Go."
  fi
  log "Go installed."
else
  log "Go $(go version | awk '{print $3}') is already installed."
fi

# ── Install lazygit via go if COPR failed earlier ─────────────────────────────
if ! is_installed lazygit && is_installed go; then
  info "Retrying lazygit install via go install (Go is now available)..."
  install_lazygit_via_go
fi

# =============================================================================
#  11. PI
# =============================================================================
section "Pi"

info "Installing Pi through Vite+..."
quiet vp install -g @earendil-works/pi-coding-agent || err "Failed to install Pi through Vite+."
log "Pi installed through Vite+."

[[ -f "$DOTFILES_DIR/pi/AGENTS.md" ]] || err "Missing Pi instructions: $DOTFILES_DIR/pi/AGENTS.md"
[[ -f "$DOTFILES_DIR/pi/settings.json" ]] || err "Missing Pi settings: $DOTFILES_DIR/pi/settings.json"
mkdir -p "$HOME/.pi/agent" || err "Failed to create $HOME/.pi/agent"
symlink "$DOTFILES_DIR/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
symlink "$DOTFILES_DIR/pi/settings.json" "$HOME/.pi/agent/settings.json"

info "Reconciling Pi packages declared in settings.json..."
pi update --extensions || err "Failed to reconcile Pi packages."
log "Pi packages reconciled."

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
  4. Start Pi (${BOLD}pi${NC}) and authenticate locally with ${BOLD}/login${NC}

  ${BLUE}Symlinks created:${NC}
  • ~/.zshrc                 → $DOTFILES_DIR/zsh/.zshrc
  • ~/.config/nvim          → $DOTFILES_DIR/nvim
  • ~/.config/tmux          → $DOTFILES_DIR/tmux
  • ~/.config/starship.toml → $DOTFILES_DIR/starship.toml
  • ~/.pi/agent/AGENTS.md   → $DOTFILES_DIR/pi/AGENTS.md
  • ~/.pi/agent/settings.json → $DOTFILES_DIR/pi/settings.json

  ${BLUE}Installed:${NC}
  zsh + oh-my-zsh, starship, zoxide, tmux + TPM, neovim, lazygit, go, Vite+ + Node.js 24 + PNPM, pi
"
