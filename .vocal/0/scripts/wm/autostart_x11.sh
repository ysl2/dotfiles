#!/bin/sh


ROOTDIR=~/.vocal/0/scripts/wm


# ==============
# === Common ===
# ==============
"$ROOTDIR"/autostart_common.sh


# =============
# === Utils ===
# =============
single_instance="$ROOTDIR"/utils/single_instance.sh


# ================
# === Touchpad ===
# ================
case "$XDG_SESSION_TYPE" in
    x11 | tty)
        # Get id of touchpad
        id="$(xinput list | grep 'Touchpad'  | cut -d'=' -f2 | awk '{print $1}')"
        # Get id of the field corresponding to natural scrolling
        id_natural_scrolling="$(xinput list-props "$id" | \
                              grep 'Natural Scrolling Enabled (' \
                              | cut -d'(' -f2 | cut -d')' -f1)"
        # Get id of the field corresponding to tapping
        id_tapping_enabled="$(xinput list-props "$id" | \
                              grep 'Tapping Enabled (' \
                              | cut -d'(' -f2 | cut -d')' -f1)"
        # Set the property to true
        xinput --set-prop "$id" "$id_natural_scrolling" 1
        xinput --set-prop "$id" "$id_tapping_enabled" 1
        ;;
esac


# ================
# === Keyboard ===
# ================
"$ROOTDIR"/autostart_x11.d/keyboard.sh


# ==============
# === Screen ===
# ==============
# Disable screen blanking and screen saver
"$single_instance" "$ROOTDIR"/autostart_x11.d/screen.sh

# # Disable screen blanking
# xset s 0 0
# xset s noblank
# xset s off
# # Disable screen saver
# xset dpms 0 0 0
# xset -dpms


# =============
# === Sound ===
# =============
# NOTE: You only need to `sudo systemctl disable gdm` then nothing else should be done here.

# Restore sound settings from file when login.
# [ -f ~/.asound.state ] && alsactl restore -f ~/.asound.state
# Keep tracking current sound settings into file.
# In fact, we don't need single_instance here, because the `sound.sh` defines a condition to exit loop.
# We use single_instance here only for preventing the accidental case.
# "$single_instance" "$ROOTDIR"/autostart_x11.d/sound.sh

# # Ref: https://wiki.archlinux.org/title/PulseAudio/Troubleshooting#Pulse_overwrites_ALSA_settings
# restore_alsa() {
#     while command -v pulseaudio > /dev/null 2>&1 && [ -z "$(pidof pulseaudio)" ]; do
#         sleep 0.5
#     done
#     alsactl -f /var/lib/alsa/asound.state restore
# }
# restore_alsa &


# ================
# === Programs ===
# ================
# killall picom 2> /dev/null; picom -D 5 -f -b --vsync
killall picom 2> /dev/null; picom -D 0 -f -b --vsync
# Clean dmenu cache
# rm ~/.cache/dmenu_run 2> /dev/null
killall unclutter 2> /dev/null; unclutter --timeout 1 &
killall dunst 2> /dev/null; dunst -config ~/.config/dunst/dunstrc &
# "$single_instance" "$ROOTDIR"/autostart_x11.d/nautilus.sh


# =============================
# === Load localhost config ===
# =============================
[ -f "$ROOTDIR"/autostart_x11.localhost.sh ] && "$ROOTDIR"/autostart_x11.localhost.sh
