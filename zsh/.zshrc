# Canonical shell configuration, linked to ~/.zshrc by install.sh.
# Keep machine-specific additions in ~/.zshrc.local (or $ZDOTDIR/.zshrc.local).
typeset -gU path
path=("$HOME/bin" "$HOME/.local/bin" /opt/homebrew/bin /usr/local/bin $path)
path+=("${VP_BIN_DIR:-${VP_HOME:-$HOME/.vite-plus}/bin}" "${XDG_DATA_HOME:-$HOME/.local/share}/vite-plus/bin")

# Vite+ supports both its current XDG layout and the legacy layout.
_vite_plus_xdg_env="${XDG_CONFIG_HOME:-$HOME/.config}/vite-plus/env"
_vite_plus_legacy_env="${VP_HOME:-$HOME/.vite-plus}/env"
if (( ! $+functions[vp] )); then
  if [[ -f "$_vite_plus_xdg_env" ]]; then
    source "$_vite_plus_xdg_env"
  elif [[ -f "$_vite_plus_legacy_env" ]]; then
    source "$_vite_plus_legacy_env"
  fi
fi
unset _vite_plus_xdg_env _vite_plus_legacy_env

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
if (( ! $+functions[omz] )) && [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Prompt and directory navigation. Palette/style live in the linked config files.
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"
export LG_CONFIG_FILE="${LG_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml}"
if (( ! $+functions[prompt_starship_precmd] )) && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
if (( ! $+functions[__zoxide_z] )) && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

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

if [[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]]; then
  source "${ZDOTDIR:-$HOME}/.zshrc.local"
fi
