#!/bin/sh
# GTK appearance for the forest theme. theme-switch.sh / session-appearance.sh
# run this file; it can also be run by hand to (re)apply.
# First installed GTK theme wins; forest prefers green-leaning variants.

S="$HOME/.config/sway/scripts"

# color-scheme drives GTK4 / libadwaita apps to their dark variant.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

pick=$(sh "$S/find-gtk-theme.sh" \
	"Graphite-green-Dark" \
	"catppuccin-frappe-green-standard+default" \
	"Orchis-Green-Dark" \
	"Graphite-Dark" \
	"Yaru-sage-dark")
if [ -n "$pick" ]; then
	sh "$S/apply-gtk-theme.sh" "$pick"
else
	sh "$S/apply-gtk-theme.sh" Adwaita-dark
fi

# Icons: Papirus with green folders to match the forest palette.
sh "$S/apply-icon-theme.sh" "Papirus-Dark" "green"

# Cursor: catppuccin pastel green.
sh "$S/apply-cursor-theme.sh" "catppuccin-frappe-green-cursors" 24
