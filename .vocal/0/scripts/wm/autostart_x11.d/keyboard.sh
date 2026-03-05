#!/bin/sh

apply_keyboard_settings() {
    case "$XDG_SESSION_TYPE" in
        x11 | tty)
            # Switch capslock and escape
            setxkbmap -option caps:swapescape
            ;;
    esac

    # Accelerate keyboard
    xset r rate 250 30
    # Disable beep sound
    xset b 0 0 0
}

get_keyboard_ids() {
    xinput list --short 2>/dev/null \
        | awk -F'id=' '/slave[[:space:]]+keyboard/ {print $2}' \
        | awk '{print $1}' \
        | tr '\n' ' '
}

watch_keyboard_hotplug() {
    apply_keyboard_settings
    last_keyboards="$(get_keyboard_ids)"

    while true; do
        current_keyboards="$(get_keyboard_ids)"

        if [ "$current_keyboards" != "$last_keyboards" ]; then
            apply_keyboard_settings
            last_keyboards="$current_keyboards"
        fi

        sleep 1
    done
}

watch_keyboard_hotplug
