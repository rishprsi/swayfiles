#!/bin/sh
# usage: screenshot.sh region-copy | region-save | screen-copy | screen-save
#   region-*  select an area with slurp;  screen-*  the focused output
#   *-copy    to clipboard;               *-save    to ~/Pictures/Screenshots
#             (saved shots are copied to the clipboard as well)

mode="${1:-region-copy}"
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"

case "$mode" in
region-*)
	geom=$(slurp -d) || exit 0 # Esc cancels
	set -- -g "$geom"
	;;
screen-*)
	out=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
	set -- -o "$out"
	;;
*)
	echo "usage: $0 region-copy|region-save|screen-copy|screen-save" >&2
	exit 1
	;;
esac

case "$mode" in
*-copy)
	grim "$@" - | wl-copy --type image/png &&
		notify-send -a screenshot -t 2000 "Screenshot copied"
	;;
*-save)
	mkdir -p "$dir"
	f="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
	grim "$@" "$f" && wl-copy --type image/png <"$f" &&
		notify-send -a screenshot -t 3000 -i "$f" "Screenshot saved" "$f"
	;;
esac
