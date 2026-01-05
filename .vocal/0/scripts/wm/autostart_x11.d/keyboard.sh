#!/bin/sh
case "$XDG_SESSION_TYPE" in
    x11 | tty)
    # Switch capslock and escape
    setxkbmap -option caps:swapescape
esac
# Acclerate keyboard
xset r rate 250 30
# Disable beep sound
xset b 0 0 0
