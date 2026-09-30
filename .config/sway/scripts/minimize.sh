#!/bin/sh
# macOS-style minimize on top of sway's scratchpad.
# Focused normal window -> hide it in the scratchpad.
# Focused window shown *from* the scratchpad (Cmd+Shift+H) -> restore it
# into the tiling layout of the current workspace.

state=$(swaymsg -t get_tree | jq -r 'first(.. | select(.focused? == true)) | .scratchpad_state // "none"')

if [ "$state" = "fresh" ] || [ "$state" = "changed" ]; then
	swaymsg floating disable >/dev/null
else
	swaymsg move scratchpad >/dev/null
fi
