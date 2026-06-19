setopt SHARE_HISTORY
# setopt INC_APPEND_HISTORY_TIME
unsetopt beep
HISTFILE=~/.bash_history
HISTSIZE=10000
SAVEHIST=10000
bindkey -e

# Enable editing the current command line with $VISUAL/$EDITOR via Ctrl-x Ctrl-e
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
