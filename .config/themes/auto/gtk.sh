#!/bin/sh
# GTK appearance for the auto theme. theme-switch.sh / session-appearance.sh
# run this file; it can also be run by hand to (re)apply.
# First installed GTK theme wins. GTK themes cannot be generated per
# wallpaper, so this uses a neutral near-black.

S="$HOME/.config/sway/scripts"

# color-scheme drives GTK4 / libadwaita apps to their dark variant.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

pick=$(sh "$S/find-gtk-theme.sh" \
	"Graphite-Dark" \
	"Orchis-Dark" \
	"catppuccin-mocha-lavender-standard+default" \
	"Yaru-dark")
if [ -n "$pick" ]; then
	sh "$S/apply-gtk-theme.sh" "$pick"
else
	sh "$S/apply-gtk-theme.sh" Adwaita-dark
fi

# Icons: Papirus with neutral blue folders (palette varies per wallpaper).
sh "$S/apply-icon-theme.sh" "Papirus-Dark" "blue"

# Cursor: variant nearest the wallpaper accent, chosen by matugen-theme.sh.
sh "$S/apply-cursor-theme.sh" "$(cat "$HOME/.config/themes/auto/cursor-theme" 2>/dev/null || echo catppuccin-frappe-dark-cursors)" 24
