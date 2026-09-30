#!/bin/sh
# Lock the screen. Safe to call repeatedly (swayidle, keybind, powermenu).
#
# gtklock: clock, user picture, and a real password box (typed characters
# shown as dots); styled from the active theme via ~/.config/gtklock.
# Falls back to swaylock (ring indicator only) if gtklock isn't installed.
#
# Returns only once the screen is actually locked, so swayidle's
# before-sleep never suspends with the desktop visible.

pgrep -x gtklock >/dev/null 2>&1 && exit 0
pgrep -x swaylock >/dev/null 2>&1 && exit 0

if command -v gtklock >/dev/null 2>&1; then
	flag="${XDG_RUNTIME_DIR:-/tmp}/swayfiles-locked.$$"
	rm -f "$flag"
	gtklock --style "$HOME/.config/gtklock/style.css" \
		--lock-command "touch $flag" >/dev/null 2>&1 &
	pid=$!
	# Wait (max ~5s) for gtklock's "locked" hook; bail out if it died.
	i=0
	while [ ! -e "$flag" ] && [ "$i" -lt 50 ] && kill -0 "$pid" 2>/dev/null; do
		sleep 0.1
		i=$((i + 1))
	done
	if [ -e "$flag" ]; then
		rm -f "$flag"
		exit 0
	fi
	kill -0 "$pid" 2>/dev/null && exit 0 # still starting; don't double-lock
	echo "gtklock failed, falling back to swaylock" >&2
fi

theme="$HOME/.config/themes/current/swaylock"
wall="$HOME/.cache/current-wallpaper.img"

set -- -f --ignore-empty-password --show-failed-attempts --indicator-caps-lock \
	--font "JetBrainsMono Nerd Font" --indicator-radius 110 --indicator-thickness 8
[ -f "$theme" ] && set -- -C "$theme" "$@"
[ -e "$wall" ] && set -- "$@" --image "$wall" --scaling fill

exec swaylock "$@"
