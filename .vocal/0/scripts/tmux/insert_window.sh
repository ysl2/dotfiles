#!/bin/bash
# tmux-insert-window.sh
# Insert current window between two specified windows
# Usage: insert_window.sh a,b or insert_window.sh n
# -1,0 means insert at the beginning (shortcut: 0)
# 6,-1 means insert at the end (shortcut: any number >= last window)
# 2,3 means insert between window 2 and 3 (target position becomes left+1)

input="$1"

if [[ -z "$input" ]]; then
    tmux display-message "Usage: insert_window.sh a,b or n (e.g., 2,3 or -1,0 or 6,-1 or 0 or 6)"
    exit 0
fi

# Get all window indices
mapfile -t all_windows < <(tmux list-windows -F '#{window_index}' | sort -n)
min_window="${all_windows[0]}"
max_window="${all_windows[-1]}"

current_index=$(tmux display-message -p '#{window_index}')

# Check if input is a single number (shortcut mode)
if [[ "$input" =~ ^[0-9]+$ ]]; then
    if [[ "$input" -le "$min_window" ]]; then
        # Insert at the beginning
        left=-1
        right="$min_window"
    elif [[ "$input" -ge "$max_window" ]]; then
        # Insert at the end
        left="$max_window"
        right=-1
    else
        # Single number in between is not allowed
        tmux display-message "Error: single number must be 0 (first) or >= $max_window (last)"
        exit 0
    fi
else
    # Parse a,b format
    IFS=',' read -r left right <<< "$input"

    # Remove spaces
    left=$(echo "$left" | tr -d ' ')
    right=$(echo "$right" | tr -d ' ')

    if [[ -z "$left" || -z "$right" ]]; then
        tmux display-message "Error: invalid format, use a,b or n"
        exit 0
    fi

    # Validate that both are integers (including negative)
    if ! [[ "$left" =~ ^-?[0-9]+$ ]] || ! [[ "$right" =~ ^-?[0-9]+$ ]]; then
        tmux display-message "Error: a and b must be integers"
        exit 0
    fi
fi

# Validate input
# Case 1: -1,-1 is invalid
if [[ "$left" -eq -1 && "$right" -eq -1 ]]; then
    tmux display-message "Error: invalid input -1,-1"
    exit 0
fi

# Case 2: -1,x means insert at the beginning, x must be the minimum window
if [[ "$left" -eq -1 ]]; then
    if [[ "$right" -ne "$min_window" ]]; then
        tmux display-message "Error: for -1,x, x must be the first window ($min_window)"
        exit 0
    fi
    target_index="$right"
# Case 3: x,-1 means insert at the end, x must be the maximum window
elif [[ "$right" -eq -1 ]]; then
    if [[ "$left" -ne "$max_window" ]]; then
        tmux display-message "Error: for x,-1, x must be the last window ($max_window)"
        exit 0
    fi
    target_index="$((left + 1))"
# Case 4: a,b are both valid windows and b = a + 1
else
    # Check if left window exists
    left_exists=false
    for w in "${all_windows[@]}"; do
        if [[ "$w" -eq "$left" ]]; then
            left_exists=true
            break
        fi
    done
    if [[ "$left_exists" == "false" ]]; then
        tmux display-message "Error: window $left does not exist"
        exit 0
    fi

    # Check if right window exists
    right_exists=false
    for w in "${all_windows[@]}"; do
        if [[ "$w" -eq "$right" ]]; then
            right_exists=true
            break
        fi
    done
    if [[ "$right_exists" == "false" ]]; then
        tmux display-message "Error: window $right does not exist"
        exit 0
    fi

    # Check right = left + 1
    if [[ "$right" -ne "$((left + 1))" ]]; then
        tmux display-message "Error: b must be a+1 (got $left,$right)"
        exit 0
    fi

    target_index="$((left + 1))"
fi

if [[ "$current_index" -eq "$target_index" ]]; then
    exit 0
fi

# Save current renumber-windows setting and disable it temporarily
renumber_setting=$(tmux show-options -gv renumber-windows 2>/dev/null || echo "off")
tmux set-option -g renumber-windows off

if [[ "$current_index" -gt "$target_index" ]]; then
    # Move forward
    for (( i = current_index; i > target_index; i-- )); do
        tmux swap-window -s ":$i" -t ":$((i - 1))"
    done
else
    # Move backward
    for (( i = current_index; i < target_index - 1; i++ )); do
        tmux swap-window -s ":$i" -t ":$((i + 1))"
    done
    target_index="$((target_index - 1))"
fi

# Restore renumber-windows setting
tmux set-option -g renumber-windows "$renumber_setting"

tmux select-window -t ":$target_index"
