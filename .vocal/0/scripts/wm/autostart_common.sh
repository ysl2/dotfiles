#!/bin/sh

# NOTE: Sync environment variables from startx shell to D-Bus and systemd.
dbus-update-activation-environment --systemd --all
