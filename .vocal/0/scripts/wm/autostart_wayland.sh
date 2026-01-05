ROOTDIR=~/.vocal/0/scripts/wm

"$ROOTDIR"/autostart_common.sh

[ -f "$ROOTDIR"/autostart_wayland.localhost.sh ] && "$ROOTDIR"/autostart_wayland.localhost.sh
