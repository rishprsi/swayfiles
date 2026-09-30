#!/bin/sh
# Apply a cursor theme across sway (live + persisted), GTK and XWayland.
# usage: apply-cursor-theme.sh <CursorThemeName> [size]

name="$1"
size="${2:-24}"
[ -n "$name" ] || { echo "usage: $0 <cursor-theme> [size]" >&2; exit 1; }

found=""
for base in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do
	[ -d "$base/$name/cursors" ] && { found=1; break; }
done
[ -n "$found" ] || { echo "cursor theme not installed: $name" >&2; exit 1; }

# 1) sway: live, and persisted in the state include so `swaymsg reload` and
#    the next login keep it (sway also exports XCURSOR_THEME/SIZE from this).
STATE="$HOME/.local/state/swayfiles"
mkdir -p "$STATE"
printf 'seat * xcursor_theme "%s" %s\n' "$name" "$size" > "$STATE/cursor.conf"
[ -n "${SWAYSOCK:-}" ] && swaymsg "seat * xcursor_theme \"$name\" $size" >/dev/null 2>&1

# 2) GTK apps read these via gsettings/xsettings.
gsettings set org.gnome.desktop.interface cursor-theme "$name"
gsettings set org.gnome.desktop.interface cursor-size "$size"

# 3) Persist into both settings.ini files for future launches.
set_ini() {
	ini="$1" key="$2" val="$3"
	mkdir -p "$(dirname "$ini")"
	[ -f "$ini" ] || printf '[Settings]\n' > "$ini"
	if grep -q "^$key=" "$ini"; then
		sed -i "s|^$key=.*|$key=$val|" "$ini"
	else
		printf '%s=%s\n' "$key" "$val" >> "$ini"
	fi
}
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
	set_ini "$ini" gtk-cursor-theme-name "$name"
	set_ini "$ini" gtk-cursor-theme-size "$size"
done

# 4) Live update running XWayland/GTK3 apps via xsettingsd (if running).
if command -v xsettingsd >/dev/null 2>&1; then
	conf="$HOME/.config/xsettingsd/xsettingsd.conf"
	mkdir -p "$(dirname "$conf")"
	touch "$conf"
	for kv in "Gtk/CursorThemeName \"$name\"" "Gtk/CursorThemeSize $size"; do
		k=${kv%% *}
		if grep -q "^$k " "$conf"; then
			sed -i "s|^$k .*|$kv|" "$conf"
		else
			printf '%s\n' "$kv" >> "$conf"
		fi
	done
	pgrep -x xsettingsd >/dev/null 2>&1 && pkill -HUP -x xsettingsd
fi

# 5) X11/legacy fallback: the "default" cursor theme inherits ours.
#    (Marker line lets session-appearance.sh remove it under GNOME.)
mkdir -p "$HOME/.local/share/icons/default"
printf '[Icon Theme]\n# managed-by: swayfiles\nName=Default\nInherits=%s\n' "$name" \
	> "$HOME/.local/share/icons/default/index.theme"

exit 0
