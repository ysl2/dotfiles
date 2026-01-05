#!/bin/sh

sound() {
    alsactl store -f ~/.asound.state
}

# The mod() function shound be put near the main loop for better precision.
curtime="$(date +%s)"
mod() {
    echo "$(( ($(date +%s) - curtime) % $1 ))"
}

# Once we logout, stop writing alsa config
# Beacuse if we logout and turn to the display manager,
# The volume will be reset to default value.
# If we keep writing alsa config, the defaule value will be dumped.
# So all we need to do is to stop writing alsa config when we logout,
# and re-login to boot this script to start writing alsa config again.
# If we have opened tmux in background, the `who`  command will show tmux session as `pts`
# So we need to filter it out.
while who | grep -v pts | grep -q "^$(whoami) "; do
    # Execute `sound()` every 1 second.
    [ "$(mod 1)" = 0 ] && sound &
    # We can define more commands here, like:
    # [ "$(mod 60)" = 0 ] && screen &
    sleep 1
done
