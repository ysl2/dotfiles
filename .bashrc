# If not running interactively, don't do anything
# if [ -z "$DESKTOP_SESSION" ] && [ -n "$-" ] && ! echo "$-" | grep -q "i"; then
# if [ -t 0 ] && [ -n "$-" ] && ! echo "$-" | grep -q "i"; then
#     return
# fi
[ -t 0 ] && case "$-" in *i*) ;; *) return ;; esac

# ===================================================
# === Utils and some global environment variables ===
# ===================================================
export VOCAL="${HOME}/.vocal"
mkdir -p "$VOCAL" >/dev/null 2>&1
VOCALOCK="${VOCAL}/.lock"
mkdir -p "$VOCALOCK" >/dev/null 2>&1

UNAME="$(uname)"
BASENAME_SHELL="${SHELL##*/}"

# Ref: https://stackoverflow.com/a/27776822/13379393
if [ "$UNAME" = Darwin ]; then
    HOMEBREW_PREFIX=/opt/homebrew
else
    HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
fi

# Get value from localhost.
[ -f ~/.bashrc.localhost.pre ] && . ~/.bashrc.localhost.pre
export MYTMUX # For neovide to use tmux.
# MYCONDA: str
# MYTMUX: str
# MYNOMIRRORFLAG: int
# MYWAYLAND: str. e.g, `sway --unsupported-gpu`

# The fcitx things must be put here (before startx or wayland), because it should be sourced when system booting.
if [ -z "$MYWAYLAND" ]; then
    export GTK_IM_MODULE=fcitx
fi
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
# For firefox two-finger scalling zoom
export MOZ_USE_XINPUT2=1

# =================================
# === Define addToPATH function ===
# =================================
export PATH
addToPATH() {
    # PATH="$1":"$PATH"
    # case ":${PATH:=$1}:" in
    #     *:"$1":*)
    #         ;;
    #     *)
    #         PATH="$1:$PATH"
    #         ;;
    # esac
    case ":$PATH:" in *:"$1":*) ;; *) PATH="$1:$PATH" ;; esac
}
# backToPATH() {
#     PATH="$PATH":"$1"
# }
searchToPATH() {
    [ ! -d "$1" ] && return
    for item in "$1"/*; do
        [ -d "${item}/bin" ] || continue
        [ -n "${item##*conda*}" ] || continue
        [ -n "${item##*forge*}" ] || continue
        PATH="${item}/bin:${PATH}"
    done
}

# ============
# === PATH ===
# ============

# ===
# === For homebrew apps.
# ===
if [ -d "$HOMEBREW_PREFIX" ]; then
    addToPATH "${HOMEBREW_PREFIX}/sbin"
    addToPATH "${HOMEBREW_PREFIX}/bin"
fi

# ===
# === For conda apps.
# ===
[ -n "$MYCONDA" ] && [ -d "${MYCONDA}/bin" ] && addToPATH "${MYCONDA}/bin"

# ===
# === No sequences, for system default.
# ===
addToPATH /sbin
addToPATH /usr/sbin
addToPATH "${HOME}/bin"
addToPATH "${HOME}/.local/bin"

# ===
# === No sequences, but put them last.
# ===
# addToPATH /var/lib/flatpak/exports/bin  # Not needed.
# addToPATH "$HOME"/.local/kitty.app/bin
addToPATH "${HOME}/.cargo/bin"
# In case if the fzf is manually installed.
# addToPATH "$HOME"/.fzf/bin
if command -v go >/dev/null 2>&1; then
    _go="$(command -v go)"
    GOPATH="${_go%/*/*}/gopath"
    addToPATH "${GOPATH}/bin"
fi
if [ -d "$HOMEBREW_PREFIX" ] && [ "$UNAME" = Darwin ]; then
    # brew install gnu-sed
    addToPATH "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
fi
addToPATH "${HOME}/.local/share/bob/nvim-bin"

# ===
# === In sequences, last in first out.
# ===
searchToPATH "$VOCAL"
addToPATH "$VOCAL"
addToPATH "${VOCAL}/0/bin"

# ===========================
# === For display manager ===
# ===========================
# if [ -n "$DISPLAY" ] && [ -z "$ZSH_VERSION" ] && [ -z "$BASH_VERSION" ]; then
#     return
# fi
# if [ "$XDG_SESSION_TYPE" != 'tty' ] && [ ! -t 0 ]; then

# Ref: https://stackoverflow.com/questions/54933530/bash-script-determine-if-script-launched-in-terminal-console-or-gui
[ ! -t 0 ] && return

# ===========================
# === For manually startx ===
# ===========================
# if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    # rm -rf ~/.Xauthority-*
    if [ -n "$MYWAYLAND" ]; then
        export LIBVA_DRIVER_NAME=nvidia
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export WLR_RENDERER=vulkan
        export WLR_NO_HARDWARE_CURSORS=1
        if [ -n "$ZSH_VERSION" ]; then
            exec ${=MYWAYLAND}
        else
            exec $MYWAYLAND
        fi
    else
        exec startx
    fi
fi
# No need: The $DISPLAY will be auto set after startx.
# For safety consideration, we still give it a default value.
# [ -z "$DISPLAY" ] && export DISPLAY=:0

# =========================
# === Boot tmux if need ===
# =========================
VOCALOCK_TMUX="$VOCALOCK"/tmux
ontmux() {
    [ ! -e "$VOCALOCK_TMUX" ] && return
    [ -n "$TMUX" ] && return

    local mytmux="$MYTMUX"
    [ ! -x "$mytmux" ] && command -v tmux &>/dev/null && mytmux=tmux
    echo "Current tmux value: \"${mytmux}\"" >"$VOCALOCK_TMUX"
    [ -z "$mytmux" ] && return

    exec "$mytmux" new-session -A -s main "$SHELL"
}
ontmux

# =============================
# === Define addTo function ===
# =============================
# Ref:
# - https://blog.csdn.net/whatday/article/details/105466009
# - https://unix.stackexchange.com/a/282433
# addTo() {
#     [ -z "${!1}" ] && eval "$1='$2'"
#     case ":${!1}:" in
#       *":$2:"*) :;;  # What does the colon `:` mean?
#       *) eval "$1='$2:${!1}'";;
#     esac
# }

# ==========================
# === Boot conda if need ===
# ==========================
VOCALOCK_CONDA="${VOCALOCK}/conda"
onconda() {
    [ ! -e "$VOCALOCK_CONDA" ] && return

    local myconda="$MYCONDA"
    if [ ! -d "$myconda" ]; then
        if [ -d "${VOCAL}/anaconda3" ]; then
            myconda="${VOCAL}/anaconda3"
        elif [ -d "${VOCAL}/miniconda3" ]; then
            myconda="${VOCAL}/miniconda3"
        fi
    fi
    echo "Current conda value: \"${myconda}\"" >"$VOCALOCK_CONDA"
    [ -z "$myconda" ] && return

    if [ -f "${myconda}/etc/profile.d/conda.sh" ]; then
        . "${myconda}/etc/profile.d/conda.sh"
    else
        # >>> conda initialize >>>
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$("${myconda}/bin/conda" "shell.${BASENAME_SHELL}" hook 2>/dev/null)"
        if [ "$?" -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "${myconda}/etc/profile.d/conda.sh" ]; then
                . "${myconda}/etc/profile.d/conda.sh"
            else
                addToPATH "${myconda}/bin"
            fi
        fi
        unset __conda_setup
        # <<< conda initialize <<<
    fi
}
onconda

# ==============
# === Others ===
# ==============
# ===
# === Beautify
# ===
# if ! command -v starship > /dev/null 2>&1 && command -v curl > /dev/null 2>&1; then
#     curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/starship/starship/master/install/install.sh | \
#     sed 's/https\:\/\/github\.com/https\:\/\/ghfast\.top\/https\:\/\/github\.com/g' | \
#     sed 's/BIN_DIR=\/usr\/local\/bin/BIN_DIR=$VOCAL/g' | sh
# fi

# ===
# === Environment variables
# ===
export LD_LIBRARY_PATH="${VOCAL}/cuda/lib64:${LD_LIBRARY_PATH}"
# Ref: https://www.reddit.com/r/zsh/comments/er6fok/getting_sign_in_output
export PROMPT_EOL_MARK=
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
else
    export EDITOR=vim
fi
export EDITOR
# 1-May-2020: Fix for Keyring error with pip. Hopefully new pip will fix it
# soon https://github.com/pypa/pip/issues/7883
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
export STARSHIP_LOG=error
export CONDA_CHANGEPS1=no
export FZF_DEFAULT_COMMAND='rg --files --hidden --no-ignore -g !.git'
export FZF_COMPLETION_TRIGGER=\\ # Press single `\<Tab>` to trigger. Double backslash for escaping.
export GO111MODULE=on
export GOPATH
# export TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata
export TESSDATA_PREFIX="${VOCAL}/tessdata_best"
if [ -d "$HOMEBREW_PREFIX" ]; then # To simulate the brew shellenv command.
    export HOMEBREW_PREFIX
    export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
    export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
    export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}"
fi
export HOMEBREW_NO_AUTO_UPDATE=1
export HISTFILE=~/.bash_history
# NOTE: Start of setting LANG and LC_ALL
# tmp="$(locale -a | grep -iE 'c\.utf|en_us\.utf')"
# tmp1="$(echo "$tmp" | grep -iE 'c\.utf')"
# [ -z "$tmp1" ] && tmp1="$(echo "$tmp" | grep -iE 'en_us\.utf')"
# export LANG="$tmp1"
# export LC_ALL="$tmp1"
# echo "$tmp1" | grep -iq 'en' && export LC_COLLATE=C
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# NOTE: End of setting LANG and LC_ALL
# For lazygit in MacOS:
export XDG_CONFIG_HOME=~/.config
# NOTE: Speed up Huggingface model downloading
# Ref: https://www.reddit.com/r/LocalLLaMA/comments/1ise5ly/speed_up_downloading_hugging_face_models_by_100x/
# pip install hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_HUB_DOWNLOAD_TIMEOUT=600
# For Chinese mirrors:
if [ "$MYNOMIRRORFLAG" != 1 ]; then
    # Node.js
    export N_NODE_MIRROR=https://npm.taobao.org/mirrors/node
    # Golang
    export GOPROXY=https://goproxy.cn
    # Homebrew
    export HOMEBREW_API_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
    export HOMEBREW_PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
    export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
    export UV_DEFAULT_INDEX=https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
    # Huggingface
    export HF_ENDPOINT=https://hf-mirror.com
fi

# ===
# === Functions
# ===
toggle() {
    [ ! -e "$1" ] && touch "$1" || rm "$1"
    eval "$2"
}
totmux() {
    toggle "$VOCALOCK_TMUX" ontmux
}
toconda() {
    toggle "$VOCALOCK_CONDA" onconda
}
P() {
    http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890 "$@"
}

# ===
# === Aliases
# ===
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias :q=exit
alias :qa=exit
# https://github.com/ranger/ranger/wiki/Integration-with-other-programs#changing-directories
ranger='source ranger ranger'
alias ranger="$ranger"
alias ra="$ranger"
alias py=python
alias ipy=ipython
# Ref: https://github.com/gokcehan/lf/blob/master/etc/lfcd.sh
lf() {
    # `command` is needed in case `lfcd` is aliased to `lf`
    \cd "$(command \lf -print-last-dir "$@")"
}
alias lD=lazydocker
alias lg=lazygit
cht() {
    curl -fsSL cht.sh/"$1"
}
jo() {
    ID="$$"
    mkdir -p /tmp/"$USER"
    OUTPUT_FILE="/tmp/${USER}/joshuto-cwd-${ID}"
    env joshuto --output-file "$OUTPUT_FILE" "$@"
    exit_code="$?"

    case "$exit_code" in
    # regular exit
    0) ;;
    # output contains current directory
    101)
        JOSHUTO_CWD="$(cat "$OUTPUT_FILE")"
        \cd "$JOSHUTO_CWD"
        ;;
    # output selected files
    102) ;;
    *)
        echo "Exit code: ${exit_code}"
        ;;
    esac
}
alias xterm='xterm -ti vt340'
# alias clash="clash -d ~/.config/clash/ -f ~/.config/clash/glados.yaml"
alias bfg="java -jar ${VOCAL}/bfg.jar"
alias fit='git --git-dir ~/.dotfiles.git --work-tree ~'
alias fat='lazygit --git-dir ~/.dotfiles.git --work-tree ~'
alias aim='nvim -u ~/.vimrc'
alias nim='nvim -u NONE'
alias ms='miniserve . -qu'
alias doom='~/.config/emacs/bin/doom'
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
alias yoink='open -a yoink'
alias glow='glow -w 150'

# ===
# === Outside sources
# ===
command -v starship >/dev/null 2>&1 && eval "$(starship init "$BASENAME_SHELL")"
if command -v fzf >/dev/null 2>&1; then
    fzf_bin="$(command -v fzf)"
    fzf_bin="$(realpath "$fzf_bin")"
    fzf_root_dir="$(dirname "$(dirname "$fzf_bin")")"
    fzf_files_array=($(find "$fzf_root_dir"/shell -maxdepth 1 -name "*.${BASENAME_SHELL}" 2>/dev/null))
    for f in "${fzf_files_array[@]}"; do
        . "$f"
    done
fi
# Note: autin must be inited after fzf beacuse there are keybinding conflict between them.
if command -v atuin >/dev/null 2>&1; then
    if [ "$BASENAME_SHELL" = bash ]; then
        if [ ! -f ~/.bashrc.bash-preexec ]; then
            command -v curl >/dev/null 2>&1 && curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bashrc.bash-preexec
        fi
        [ -f ~/.bashrc.bash-preexec ] && . ~/.bashrc.bash-preexec
    fi
    eval "$(atuin init "$BASENAME_SHELL")"
fi
# command -v mcfly > /dev/null 2>&1 && eval "$(mcfly init $(basename "$SHELL"))"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init "$BASENAME_SHELL")"
# Prevent nautilus from generating core dump file.
ulimit -c 0

# ===============
# === For zsh ===
# ===============
if [ -n "$ZSH_VERSION" ]; then
    [ -f ~/.bashrc.zsh ] && . ~/.bashrc.zsh
fi

# ==================
# === Post loads ===
# ==================
[ -f ~/.bashrc.localhost.post ] && . ~/.bashrc.localhost.post

# ========================
# === Unique varaibles ===
# ========================
uniqTo() {
    content="$(eval "echo \$$1")"
    eval "$1=$(echo -n "$content" | tr ":" "\n" | awk '!x[$0]++' | tr "\n" ":")"
}
tmp="$(uname -a)"
if [[ ! "$tmp" == *MINGW64* ]] && [[ ! "$tmp" == *WSL* ]]; then
    uniqTo PATH
fi
uniqTo LD_LIBRARY_PATH
