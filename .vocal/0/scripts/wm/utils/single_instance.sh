#!/bin/sh

main() {
    for cmd in "$@"; do
        pids=$(pgrep -f "$cmd" | grep -v "^$$\$")
        for pid in $pids; do
            kill -9 "$pid"
        done
        $cmd &
    done
}

main "$@"
