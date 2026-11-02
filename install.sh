#!/bin/bash
# Bootstrap macOS, clone the dotfiles, and link their versioned configurations.
# Compatible with the macOS system Bash (3.2).
set -Eeuo pipefail

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--dry-run] [--help]' \
    '' \
    'Prepares the development environment, installing missing components:' \
    '  Official bootstraps: Homebrew, Oh My Zsh, Vite+' \
    '  Native tools: git, curl, unzip, zsh, lua, luarocks, cmake, pkgconf,' \
    '                neovim, lazygit, starship, ripgrep, fd, fzf, zoxide' \
    '  Vite+: Node.js >=22.19, pnpm, Pi and Codex CLI' \
    '  Configs: Zsh, Starship, Neovim and Lazygit, linked from ~/dotfiles' \
    '' \
    'Options:' \
    '  --dry-run   Show the plan without downloads, installs or file changes' \
    '  -h, --help  Show this help' \
    '' \
    'macOS only. Run as your normal user, never with sudo.' \
    'Apple developer tools and Homebrew may require system authorization.' \
    'Existing tools and Vite+ defaults are reused. Missing Node uses version 24.' \
    'Environment overrides:' \
    '  DOTFILES_DIR     Checkout path (default: $HOME/dotfiles)' \
    '  DOTFILES_REPO    Clone URL (default: https://github.com/sonomandeep/dotfiles.git)' \
    '  DOTFILES_BRANCH  Branch to clone (default: main)' \
    '  XDG_CONFIG_HOME Configuration directory (default: $HOME/.config)' \
    '  ZDOTDIR         Zsh configuration directory (default: $HOME)' \
    '' \
    'Existing checkouts are reused without pull/reset, even with local changes.' \
    'Conflicting configs/symlinks get dated backups; correct links are kept.' \
    'Official bootstraps may add their own PATH integration to shell files.' \
    'No generated themes, agent settings/credentials or project pins are managed.'
}

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done
info() { printf '  %s\n' "$*"; }
die() { printf '\nError: %s\n' "$*" >&2; exit 1; }
trap 'printf "\nSetup failed at line %s: %s\nFix the error and re-run; installed components will be reused.\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
TEMP_DIR=''
cleanup() { if [[ -n "$TEMP_DIR" ]]; then rm -rf -- "$TEMP_DIR"; fi; }
trap cleanup EXIT
run() {
  printf '\n  $'; printf ' %q' "$@"; printf '\n'
  if ! $DRY_RUN; then "$@"; fi
}

[[ "$(uname -s)" == Darwin ]] || die 'This installer currently supports macOS only.'
[[ "$EUID" -ne 0 ]] || die 'Run as your normal user, not with sudo.'
export PATH="$PATH:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin"
export PATH="$PATH:${VP_BIN_DIR:-${VP_HOME:-$HOME/.vite-plus}/bin}"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1
COMMANDS=(git curl unzip zsh lua luarocks cmake pkg-config nvim lazygit starship rg fd fzf zoxide)
FORMULAE=(git curl unzip zsh lua luarocks cmake pkgconf neovim lazygit starship ripgrep fd fzf zoxide)
MISSING_FORMULAE=()
AGENT_PACKAGES=()
OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
PLUGINS=(zsh-autosuggestions zsh-syntax-highlighting)
PLUGIN_URLS=(https://github.com/zsh-users/zsh-autosuggestions.git https://github.com/zsh-users/zsh-syntax-highlighting.git)
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S).$$"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/sonomandeep/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
[[ "$DOTFILES_DIR" == /* && "$CONFIG_HOME" == /* && "$ZSHRC" == /* ]] ||
  die 'DOTFILES_DIR, XDG_CONFIG_HOME and ZDOTDIR must resolve to absolute paths.'
DOTFILES_DIR="${DOTFILES_DIR%/}"
[[ -n "$DOTFILES_DIR" && "$DOTFILES_DIR" != "$HOME" ]] || die 'Choose a dedicated directory for DOTFILES_DIR.'
if [[ -e "$DOTFILES_DIR" || -L "$DOTFILES_DIR" ]]; then
  [[ -d "$DOTFILES_DIR/.git" || -f "$DOTFILES_DIR/.git" ]] ||
    die "Destination exists but is not a Git checkout: $DOTFILES_DIR. Move it aside or choose DOTFILES_DIR."
fi
CONFIG_SOURCES=(zsh/.zshrc starship.toml nvim lazygit/config.yml)
CONFIG_TARGETS=("$ZSHRC" "$CONFIG_HOME/starship.toml" "$CONFIG_HOME/nvim" "$CONFIG_HOME/lazygit/config.yml")
# Lazygit on macOS uses Application Support when launched outside our shell.
if [[ "$CONFIG_HOME/lazygit/config.yml" != "$HOME/Library/Application Support/lazygit/config.yml" ]]; then
  CONFIG_SOURCES+=(lazygit/config.yml)
  CONFIG_TARGETS+=("$HOME/Library/Application Support/lazygit/config.yml")
fi

# Download official installers before executing them, with cleanup on failure.
bootstrap() {
  local name="$1" url="$2" interpreter="$3" file
  shift 3
  if $DRY_RUN; then
    info "DOWNLOAD $url"
    run env "$@" "$interpreter" "<downloaded-$name-installer>"
    return
  fi
  if [[ -z "$TEMP_DIR" ]]; then
    TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dev-install.XXXXXX")"
  fi
  file="$TEMP_DIR/$name.sh"
  run curl --fail --silent --show-error --location "$url" --output "$file"
  run env "$@" "$interpreter" "$file"
}

# Read the installed inventory, not executable shims: --version on a shim can
# download a runtime. Prefer a compatible installed default, otherwise the newest.
managed_version() {
  local inventory
  inventory="$("$VP" env list "$1" 2>&1)" || {
    printf '%s\n' "$inventory" >&2; return 1
  }
  printf '%s\n' "$inventory" | awk -v scope="$1" '
    $1 == "*" {
      version = $2; sub(/^v/, "", version)
      if (version !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) next
      split(version, p, ".")
      if (scope == "node" && (p[1] < 22 || (p[1] == 22 && p[2] < 19))) next
      if (!best || p[1] > major || (p[1] == major && p[2] > minor) ||
          (p[1] == major && p[2] == minor && p[3] > patch)) {
        best = version; major = p[1]; minor = p[2]; patch = p[3]
      }
      if ($0 ~ / default([[:space:]]|$)/) preferred = version
    }
    END { print preferred ? preferred : best }
  '
}

# Preserve files, directories and symlinks without following their targets.
backup_config() {
  local destination="$1" backup="$1.backup-$BACKUP_SUFFIX" counter=0
  while [[ -e "$backup" || -L "$backup" ]]; do
    counter=$((counter + 1)); backup="$destination.backup-$BACKUP_SUFFIX.$counter"
  done
  mv "$destination" "$backup"
  info "BACKUP   $backup"
}

# Official installers must not append to a tracked .zshrc through a symlink.
# This temporary regular file is replaced by the canonical link after setup.
prepare_shell_for_bootstraps() {
  local file=''
  mkdir -p "$(dirname "$ZSHRC")"
  if [[ -e "$ZSHRC" || -L "$ZSHRC" ]]; then
    [[ ! -d "$ZSHRC" ]] || die "Expected a shell file, found a directory: $ZSHRC"
    if [[ -r "$ZSHRC" ]]; then
      file="$(mktemp "${ZSHRC}.tmp.XXXXXX")"
      cp -pL "$ZSHRC" "$file"
    fi
    backup_config "$ZSHRC"
  fi
  if [[ -n "$file" ]]; then mv "$file" "$ZSHRC"; else (set -o noclobber; : > "$ZSHRC"); fi
}

ensure_dotfiles() {
  local root
  if [[ -d "$DOTFILES_DIR/.git" || -f "$DOTFILES_DIR/.git" ]]; then
    root="$(git -C "$DOTFILES_DIR" rev-parse --show-toplevel)"
    [[ "$root" == "$(cd "$DOTFILES_DIR" && pwd -P)" ]] || die 'DOTFILES_DIR is not the root of a Git checkout.'
    info "REUSE    $DOTFILES_DIR (no pull/reset; local changes preserved)"
  else
    run mkdir -p "$(dirname "$DOTFILES_DIR")"
    run git clone --branch "$DOTFILES_BRANCH" --single-branch -- "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

validate_config_sources() {
  local relative source destination i
  # A fresh remote dry run deliberately does not download the repository.
  if $DRY_RUN && [[ ! -d "$DOTFILES_DIR" ]]; then return; fi
  for ((i = 0; i < ${#CONFIG_SOURCES[@]}; i++)); do
    relative="${CONFIG_SOURCES[$i]}"
    source="$DOTFILES_DIR/$relative"
    destination="${CONFIG_TARGETS[$i]}"
    [[ -e "$source" ]] || die "Missing config source: $source. Update the checkout explicitly and re-run."
    [[ "$source" != "$destination" && "$source" != "$destination/"* ]] ||
      die "Unsafe config destination contains its source: $destination"
  done
  zsh -n "$DOTFILES_DIR/zsh/.zshrc"
}

link_config() {
  local source="$1" destination="$2"
  if [[ -L "$destination" && "$(readlink "$destination")" == "$source" ]]; then
    info "OK       $destination already linked"
    return
  fi
  if $DRY_RUN; then
    if [[ -e "$destination" || -L "$destination" ]]; then info "BACKUP   $destination (dated backup)"; fi
    info "LINK     $destination -> $source"
    return
  fi
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" || -L "$destination" ]]; then backup_config "$destination"; fi
  ln -s "$source" "$destination"
  info "LINK     $destination -> $source"
}

printf '\nDevelopment environment setup\n'
$DRY_RUN && info 'Dry run: no changes will be made.'
for ((i = 0; i < ${#COMMANDS[@]}; i++)); do
  tool="${COMMANDS[$i]}"
  if command -v "$tool" >/dev/null 2>&1; then
    info "OK       $tool ($(command -v "$tool"))"
  else
    info "INSTALL  $tool (Homebrew: ${FORMULAE[$i]})"
    MISSING_FORMULAE+=("${FORMULAE[$i]}")
  fi
done
for tool in pi codex; do
  if command -v "$tool" >/dev/null 2>&1; then
    info "OK       $tool ($(command -v "$tool"))"
  else
    info "INSTALL  $tool (Vite+ global package)"
    case "$tool" in
      pi) AGENT_PACKAGES+=("@earendil-works/pi-coding-agent") ;;
      codex) AGENT_PACKAGES+=("@openai/codex") ;;
    esac
  fi
done
# Refuse to overwrite partial installations or unrelated directories.
if [[ ! -r "$OMZ_DIR/oh-my-zsh.sh" && ( -e "$OMZ_DIR" || -L "$OMZ_DIR" ) ]]; then
  die "Oh My Zsh destination exists but is incomplete: $OMZ_DIR. Move it aside and re-run."
fi
for plugin in "${PLUGINS[@]}"; do
  destination="$CUSTOM_DIR/plugins/$plugin"
  if [[ ! -r "$destination/$plugin.plugin.zsh" && ! -r "$destination/$plugin.zsh" &&
        ( -e "$destination" || -L "$destination" ) ]]; then
    die "Plugin destination exists but is incomplete: $destination. Move it aside and re-run."
  fi
done

# Homebrew's official installer also installs Apple's developer tools when needed.
if ! command -v brew >/dev/null 2>&1; then
  info 'Homebrew installation may ask for administrator authorization.'
  # stdin can be the curl pipe; read system authorization from the terminal.
  if [[ -t 2 && -r /dev/tty ]]; then run sudo -v < /dev/tty; fi
  bootstrap homebrew https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /bin/bash NONINTERACTIVE=1
  hash -r
fi
BREW="$(command -v brew || printf brew)"
if ! $DRY_RUN; then
  command -v "$BREW" >/dev/null 2>&1 || die 'Homebrew bootstrap did not make brew available.'
  export PATH="$("$BREW" --prefix)/bin:$PATH"
fi
if ! xcode-select -p >/dev/null 2>&1; then
  run xcode-select --install
  if ! $DRY_RUN; then
    info 'Complete the Apple developer-tools dialog; waiting up to 30 minutes...'
    for ((attempt = 0; attempt < 360; attempt++)); do
      if xcode-select -p >/dev/null 2>&1; then break; fi
      sleep 5
    done
    xcode-select -p >/dev/null 2>&1 || die 'Developer tools are still unavailable; complete installation and re-run.'
  fi
fi
if [[ ${#MISSING_FORMULAE[@]} -gt 0 ]]; then
  run "$BREW" install "${MISSING_FORMULAE[@]}"
fi

# Git is now available, even when this installer itself arrived through curl.
ensure_dotfiles
validate_config_sources

# Keep bootstraps away from any existing tracked .zshrc symlink.
if [[ ! -r "$OMZ_DIR/oh-my-zsh.sh" ]] || ! command -v vp >/dev/null 2>&1; then
  run prepare_shell_for_bootstraps
fi
if [[ ! -r "$OMZ_DIR/oh-my-zsh.sh" ]]; then
  bootstrap ohmyzsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh sh \
    "ZSH=$OMZ_DIR" "ZDOTDIR=${ZDOTDIR:-$HOME}" RUNZSH=no CHSH=no KEEP_ZSHRC=yes
fi
for ((i = 0; i < ${#PLUGINS[@]}; i++)); do
  plugin="${PLUGINS[$i]}"
  destination="$CUSTOM_DIR/plugins/$plugin"
  if [[ ! -r "$destination/$plugin.plugin.zsh" && ! -r "$destination/$plugin.zsh" ]]; then
    run mkdir -p "$CUSTOM_DIR/plugins"
    run git clone --depth 1 -- "${PLUGIN_URLS[$i]}" "$destination"
  fi
done

NEW_VP=false
if ! command -v vp >/dev/null 2>&1; then
  NEW_VP=true
  bootstrap viteplus https://viteplus.dev/install.sh /bin/bash VP_NODE_MANAGER=yes CI=1
  hash -r
fi
VP="$(command -v vp || printf vp)"
if ! $DRY_RUN; then
  command -v "$VP" >/dev/null 2>&1 || die 'Vite+ bootstrap did not make vp available.'
fi
NODE_VERSION=''
PNPM_VERSION=''
if ! $NEW_VP || ! $DRY_RUN; then
  NODE_VERSION="$(managed_version node)"
  PNPM_VERSION="$(managed_version pnpm)"
fi
if [[ -z "$NODE_VERSION" ]]; then
  run "$VP" env install node@24
  if $DRY_RUN; then NODE_VERSION=24; else NODE_VERSION="$(managed_version node)"; fi
fi
if [[ -z "$PNPM_VERSION" ]]; then
  run "$VP" env install pnpm@latest
  if $DRY_RUN; then PNPM_VERSION=latest; else PNPM_VERSION="$(managed_version pnpm)"; fi
fi
[[ -n "$NODE_VERSION" && -n "$PNPM_VERSION" ]] || die 'Vite+ runtime installation is incomplete.'
info "USE      Node.js $NODE_VERSION / pnpm $PNPM_VERSION (Vite+ managed)"
if $NEW_VP; then
  # Only initialize a newly installed manager. Never reset an existing setup.
  run "$VP" env default "node@$NODE_VERSION" "pnpm@$PNPM_VERSION"
fi
if [[ ${#AGENT_PACKAGES[@]} -gt 0 ]]; then
  run "$VP" install --global --node "$NODE_VERSION" --ignore-scripts "${AGENT_PACKAGES[@]}"
fi
for ((i = 0; i < ${#CONFIG_SOURCES[@]}; i++)); do
  link_config "$DOTFILES_DIR/${CONFIG_SOURCES[$i]}" "${CONFIG_TARGETS[$i]}"
done

# macOS already lists /bin/zsh as a valid login shell; do not edit /etc/shells.
LOGIN_ZSH=/bin/zsh
CURRENT_SHELL="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
if [[ "$CURRENT_SHELL" != "$LOGIN_ZSH" ]]; then
  info 'Changing the login shell to Zsh may ask for your account password.'
  run chsh -s "$LOGIN_ZSH"
fi
if $DRY_RUN; then
  printf '\nDry run complete. No files or packages were changed.\n'
  exit 0
fi

printf '\nVerifying development environment...\n'
"$VP" env exec --node "$NODE_VERSION" node --version
"$VP" env exec --node "$NODE_VERSION" --package-manager "pnpm@$PNPM_VERSION" pnpm --version
for tool in "${COMMANDS[@]}" cc make tar pi codex; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is still missing from PATH."
done
[[ -r "$OMZ_DIR/oh-my-zsh.sh" ]] || die 'Oh My Zsh installation is incomplete.'
for plugin in "${PLUGINS[@]}"; do
  destination="$CUSTOM_DIR/plugins/$plugin"
  [[ -r "$destination/$plugin.plugin.zsh" || -r "$destination/$plugin.zsh" ]] || die "Plugin is missing: $plugin"
done
zsh -n "$ZSHRC"
printf '\nReady. Open a new Rex session, or run: exec zsh -l\n'
info 'Zsh plugins, Starship, Zoxide, PATH and the Neovim editor are enabled.'
info "Configurations are linked from $DOTFILES_DIR; previous conflicting targets were backed up."
info 'Pi/Codex settings, credentials and sessions remain machine-local.'
info 'Authenticate Pi with /login and Codex with codex login when needed.'
