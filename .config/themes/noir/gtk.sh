#!/bin/sh
# GTK appearance for the noir theme. theme-switch.sh / session-appearance.sh
# run this file; it can also be run by hand to (re)apply.
# First installed GTK theme wins; noir prefers the near-black Graphite.

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

# Icons: Papirus with grey folders to match noir's neutral palette.
sh "$S/apply-icon-theme.sh" "Papirus-Dark" "grey"

# Cursor: catppuccin steel blue, matching noir's accent.
sh "$S/apply-cursor-theme.sh" "catppuccin-frappe-blue-cursors" 24
