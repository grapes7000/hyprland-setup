# Managed by hyprland-setup. Personal additions belong in ~/.zshrc.local.

export ZSH="/usr/share/oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Starship replaces Powerlevel10k. Keep Oh My Zsh theme-free so it cannot
# overwrite the prompt after Starship initializes.
ZSH_THEME=""
plugins=(git sudo colored-man-pages command-not-found)

source "$ZSH/oh-my-zsh.sh"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

if [ -r /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
fi
if [ -r /usr/share/fzf/completion.zsh ]; then
    source /usr/share/fzf/completion.zsh
fi

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
eval "$(thefuck --alias)"
eval "$(starship init zsh)"

alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias cat='bat'
alias find='fd'

if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

# Keep syntax highlighting last: it wraps the line editor used by the plugins above.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
