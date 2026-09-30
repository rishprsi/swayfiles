#!/bin/sh
# (Re)generate the "auto" theme from a wallpaper via matugen.
# usage: matugen-theme.sh /path/to/image
#
# Templates live in ~/.config/matugen/templates and render into
# ~/.config/themes/auto (see ~/.config/matugen/config.toml).

wall=$(readlink -f "$1") # resolve symlinks; matugen sniffs the extension
[ -f "$wall" ] || { echo "usage: $0 <image>" >&2; exit 1; }
command -v matugen >/dev/null 2>&1 || { echo "matugen not installed" >&2; exit 1; }

THEMES_DIR="$HOME/.config/themes"
AUTO="$THEMES_DIR/auto"
mkdir -p "$AUTO/wallpapers"

# --prefer picks among candidate source colors without a tty; saturation
# gives the liveliest accent (matugen still tones it pastel for dark mode).
matugen image "$wall" --mode dark --prefer saturation >/dev/null || exit 1

# Cursor: pick the installed catppuccin variant whose accent hue is
# closest to the generated accent color (low saturation -> neutral dark).
# Hex is decoded in the shell: Ubuntu's awk is mawk (no strtonum).
accent=$(sed -n 's/@define-color accent #\([0-9a-fA-F]\{6\}\);/\1/p' "$AUTO/waybar.css" | head -n1)
if [ -n "$accent" ]; then
	r=$((0x$(echo "$accent" | cut -c1-2)))
	g=$((0x$(echo "$accent" | cut -c3-4)))
	b=$((0x$(echo "$accent" | cut -c5-6)))
	pick=$(awk -v r="$r" -v g="$g" -v b="$b" 'BEGIN {
		mx = r > g ? r : g; mx = mx > b ? mx : b
		mn = r < g ? r : g; mn = mn < b ? mn : b
		d = mx - mn
		sat = mx == 0 ? 0 : d / mx
		if (d == 0 || sat < 0.12) { print "dark"; exit }
		if (mx == r)      { h = (g - b) / d; while (h < 0) h += 6; while (h >= 6) h -= 6 }
		else if (mx == g) h = (b - r) / d + 2
		else              h = (r - g) / d + 4
		h *= 60
		# catppuccin frappe accent hues
		n = split("peach:20 yellow:40 green:96 teal:172 sky:189 blue:222 lavender:239 mauve:277 pink:316 red:359", arr, " ")
		best = "dark"; bestd = 999
		for (i = 1; i <= n; i++) {
			split(arr[i], kv, ":")
			dd = h - kv[2]; if (dd < 0) dd = -dd
			if (dd > 180) dd = 360 - dd
			if (dd < bestd) { bestd = dd; best = kv[1] }
		}
		print best
	}')
	theme="catppuccin-frappe-$pick-cursors"
	[ -d "$HOME/.local/share/icons/$theme" ] && printf '%s\n' "$theme" >"$AUTO/cursor-theme"
fi

# Shared wallpaper pool: symlink every manual theme's wallpapers so the
# shuffler works under auto (each change re-derives the palette).
find "$AUTO/wallpapers" -maxdepth 1 -type l -delete 2>/dev/null
for dir in "$THEMES_DIR"/*/wallpapers; do
	theme=$(basename "$(dirname "$dir")")
	{ [ "$theme" = "auto" ] || [ "$theme" = "current" ]; } && continue
	find -L "$dir" -maxdepth 1 -type f \
		\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) |
		while IFS= read -r f; do
			ln -sfn "$f" "$AUTO/wallpapers/$theme-$(basename "$f")"
		done
done
