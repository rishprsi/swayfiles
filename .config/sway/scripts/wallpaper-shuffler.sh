#!/bin/sh
# Set a random wallpaper from the active theme's folder every INTERVAL
# seconds (first one right away at login). Started from sway autostart.

WALLDIR="$HOME/.config/themes/current/wallpapers"
INTERVAL=3600

# Only one shuffler per session.
pid="${XDG_RUNTIME_DIR:-/tmp}/swayfiles-shuffler.pid"
if [ -f "$pid" ] && kill -0 "$(cat "$pid")" 2>/dev/null; then exit 0; fi
echo $$ >"$pid"

while :; do
	wall=$(find -L "$WALLDIR" -type f \
		\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
		2>/dev/null | shuf -n 1)
	[ -n "$wall" ] && sh "$HOME/.config/sway/scripts/set-wallpaper.sh" "$wall"
	sleep "$INTERVAL"
done
