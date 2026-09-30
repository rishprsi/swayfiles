#!/bin/sh
# Rofi wallpaper picker with thumbnails, listing every theme's wallpapers
# (grouped as "theme/file"). If the auto theme is active the palette
# regenerates from the pick.

THEMES_DIR="$HOME/.config/themes"

choice=$(
	for dir in "$THEMES_DIR"/*/wallpapers; do
		theme=$(basename "$(dirname "$dir")")
		# current duplicates the active theme; auto pools symlinks to the rest
		[ "$theme" = "current" ] && continue
		[ "$theme" = "auto" ] && continue
		find -L "$dir" -maxdepth 1 -type f \
			\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) |
			sort | while IFS= read -r f; do
				# \037 = the 0x1f field separator (dash's printf has no \x).
				printf '%s/%s\0icon\037%s\n' "$theme" "$(basename "$f")" "$f"
			done
	done | rofi -dmenu -i -p "wallpaper" -show-icons \
		-theme-str 'element-icon { size: 5em; }'
)

[ -n "$choice" ] || exit 0
theme=${choice%%/*}
file=${choice#*/}
sel="$THEMES_DIR/$theme/wallpapers/$file"
[ -f "$sel" ] && sh "$HOME/.config/sway/scripts/set-wallpaper.sh" "$sel"
