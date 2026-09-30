#!/bin/sh
# Rofi menu to pick an installed dark GTK theme and apply it on the fly.
# usage: gtk-theme-switch.sh [theme-name]   (no arg -> rofi picker)

SCRIPTS="$HOME/.config/sway/scripts"

choice="$1"
if [ -z "$choice" ]; then
	list=$(
		for base in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes; do
			[ -d "$base" ] && find "$base" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
		done | grep -iE 'graphite|orchis|catppuccin|yaru|adwaita' | grep -iE 'dark' |
			grep -vE 'hdpi$' | sort -u
	)
	[ -n "$list" ] || { notify-send "GTK themes" "No dark GTK themes installed" 2>/dev/null; exit 0; }
	choice=$(printf '%s\n' "$list" | rofi -dmenu -i -p "gtk theme")
fi
[ -n "$choice" ] || exit 0

sh "$SCRIPTS/apply-gtk-theme.sh" "$choice"
