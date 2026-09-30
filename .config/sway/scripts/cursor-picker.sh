#!/bin/sh
# Rofi picker for installed cursor themes (any dir shipping a cursors/
# subdir). The active theme is marked; picking applies live everywhere.

current=$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")

choice=$(
	for base in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do
		[ -d "$base" ] || continue
		for d in "$base"/*/cursors; do
			[ -d "$d" ] && basename "$(dirname "$d")"
		done
	done | sort -u | grep -v '^default$' | while IFS= read -r t; do
		if [ "$t" = "$current" ]; then
			printf '%s   \n' "$t"
		else
			printf '%s\n' "$t"
		fi
	done | rofi -dmenu -i -p "cursor" | awk '{print $1}'
)

[ -n "$choice" ] || exit 0
sh "$HOME/.config/sway/scripts/apply-cursor-theme.sh" "$choice" 24 &&
	notify-send -a theme "Cursor theme" "$choice"
