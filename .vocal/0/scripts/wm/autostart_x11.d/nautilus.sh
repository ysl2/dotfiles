#!/bin/sh

while true; do
    while [ -z "$(ps aux | grep -v grep | grep 'nautilus --gapplication-service')" ]; do
        nautilus --gapplication-service > /dev/null 2>&1 &
    done
    # [ -e ~/core ] && rm -f ~/core
    sleep 0.5
done
