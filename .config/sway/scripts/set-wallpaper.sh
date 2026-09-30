#!/bin/sh
# Apply a wallpaper on all outputs and remember the choice.
# usage: set-wallpaper.sh /path/to/image [--no-reload]

wall="$1"
[ -f "$wall" ] || { echo "usage: $0 <image>" >&2; exit 1; }
wall=$(readlink -f "$wall")

STATE="$HOME/.local/state/swayfiles"
mkdir -p "$STATE" "$HOME/.cache"

# Persist for the next login / `swaymsg reload` (included by sway config).
printf 'output * bg "%s" fill\n' "$wall" >"$STATE/wallpaper.conf"

# Live. sway runs swaybg itself.
[ -n "${SWAYSOCK:-}" ] && swaymsg "output * bg \"$wall\" fill" >/dev/null 2>&1

printf '%s\n' "$wall" >"$HOME/.cache/current-wallpaper"
# Stable path for consumers that need an image file (swaylock background).
ln -sfn "$wall" "$HOME/.cache/current-wallpaper.img"

# If the matugen-based "auto" theme is active, its palette follows the
# wallpaper: regenerate the theme files and restyle everything.
current=$(basename "$(readlink "$HOME/.config/themes/current" 2>/dev/null)")
if [ "$current" = "auto" ] && [ "${2:-}" != "--no-reload" ]; then
	S="$HOME/.config/sway/scripts"
	sh "$S/matugen-theme.sh" "$wall" &&
		sh "$HOME/.config/themes/auto/gtk.sh" &&
		sh "$S/theme-reload.sh"
fi
exit 0
