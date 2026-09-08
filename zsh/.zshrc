# Base PATH shared by Fedora and macOS.
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Vite+ supports both its current XDG layout and the legacy layout.
_vite_plus_xdg_env="${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env"
_vite_plus_legacy_env="$HOME/.vite-plus/env"
if [[ -f "$_vite_plus_xdg_env" ]]; then
  source "$_vite_plus_xdg_env"
elif [[ -f "$_vite_plus_legacy_env" ]]; then
  source "$_vite_plus_legacy_env"
fi
unset _vite_plus_xdg_env _vite_plus_legacy_env

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  z
)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Prompt and directory navigation.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

export EDITOR="nvim"
export VISUAL="nvim"

alias vim="nvim"
alias vi="nvim"
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias ll="ls -lah -G"
  alias la="ls -A -G"
  command -v brew >/dev/null 2>&1 && brew list --versions libpq >/dev/null 2>&1 && export PATH="$(brew --prefix libpq)/bin:$PATH"
else
  alias ll="ls -lah --color=auto"
  alias la="ls -A --color=auto"
  alias grep="grep --color=auto"
fi

if command -v go >/dev/null 2>&1; then
  GOPATH="$(go env GOPATH 2>/dev/null)"
  [[ -n "$GOPATH" ]] && export PATH="$GOPATH/bin:$PATH"
fi

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
