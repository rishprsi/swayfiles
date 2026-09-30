#!/bin/sh
# Apply an icon theme across GTK3, GTK4, and (live) running apps.
# usage: apply-icon-theme.sh <IconThemeName> [papirus-folder-color]
#
# The optional second arg recolors Papirus folder icons (needs the
# papirus-folders script and a user-writable Papirus install, i.e.
# ~/.local/share/icons).

name="$1"
color="$2"
[ -n "$name" ] || { echo "usage: $0 <icon-theme> [folder-color]" >&2; exit 1; }

# Not installed yet (fresh machine before install.sh): use Ubuntu's own
# icons instead of pointing GTK at a missing theme.
installed() {
	for base in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do
		[ -f "$base/$1/index.theme" ] && return 0
	done
	return 1
}
if ! installed "$name"; then
	echo "icon theme not installed: $name" >&2
	for fallback in Yaru-dark Yaru Adwaita; do
		installed "$fallback" && { name="$fallback"; break; }
	done
fi

# 1) Record the choice (GTK3 apps read this via xsettings).
gsettings set org.gnome.desktop.interface icon-theme "$name"

# 2) Persist into both settings.ini files so future launches use it.
set_ini() {
	ini="$1"
	mkdir -p "$(dirname "$ini")"
	[ -f "$ini" ] || printf '[Settings]\n' > "$ini"
	if grep -q '^gtk-icon-theme-name=' "$ini"; then
		sed -i "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$name|" "$ini"
	else
		printf 'gtk-icon-theme-name=%s\n' "$name" >> "$ini"
	fi
}
set_ini "$HOME/.config/gtk-3.0/settings.ini"
set_ini "$HOME/.config/gtk-4.0/settings.ini"

# 3) Live update running GTK3 apps via xsettingsd (if available).
if command -v xsettingsd >/dev/null 2>&1; then
	conf="$HOME/.config/xsettingsd/xsettingsd.conf"
	mkdir -p "$(dirname "$conf")"
	touch "$conf"
	if grep -q '^Net/IconThemeName' "$conf"; then
		sed -i "s|^Net/IconThemeName.*|Net/IconThemeName \"$name\"|" "$conf"
	else
		printf 'Net/IconThemeName "%s"\n' "$name" >> "$conf"
	fi
	if pgrep -x xsettingsd >/dev/null 2>&1; then
		pkill -HUP -x xsettingsd
	else
		setsid xsettingsd >/dev/null 2>&1 < /dev/null &
	fi
fi

# 4) Per-theme folder accent for Papirus.
PF="$HOME/.local/bin/papirus-folders"
recolored=0
case "$name" in
	Papirus*)
		if [ -n "$color" ] && [ -x "$PF" ]; then
			"$PF" -C "$color" -t "$name" >/dev/null 2>&1 && recolored=1
		fi
		;;
esac

# 5) Recoloring changes files *inside* an already-selected theme, which
# running apps have rasterized and cached in memory. Refresh the on-disk
# caches and bounce nautilus (a resident daemon) so it re-reads icons.
if [ "$recolored" -eq 1 ]; then
	if command -v gtk-update-icon-cache >/dev/null 2>&1; then
		for t in Papirus Papirus-Dark; do
			[ -d "$HOME/.local/share/icons/$t" ] \
				&& gtk-update-icon-cache -q -f "$HOME/.local/share/icons/$t"
		done
	fi
	pgrep -x nautilus >/dev/null 2>&1 && nautilus -q >/dev/null 2>&1
fi

exit 0
