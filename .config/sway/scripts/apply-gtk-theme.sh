#!/bin/sh
# Apply a GTK theme name across GTK3, GTK4/libadwaita, and (live) running apps.
# usage: apply-gtk-theme.sh <ThemeName>

name="$1"
[ -n "$name" ] || { echo "usage: $0 <theme-name>" >&2; exit 1; }

# Locate the theme dir in the usual user/system locations.
themedir=""
for d in "$HOME/.themes/$name" "$HOME/.local/share/themes/$name" "/usr/share/themes/$name"; do
	[ -d "$d" ] && { themedir="$d"; break; }
done
[ -n "$themedir" ] || { echo "gtk theme not found: $name" >&2; exit 1; }

# 1) Record the choice (GTK3 apps read this via xsettings; also our source of truth).
gsettings set org.gnome.desktop.interface gtk-theme "$name"

# 2) Persist into both settings.ini files so future launches use it.
set_ini() {
	ini="$1"
	mkdir -p "$(dirname "$ini")"
	[ -f "$ini" ] || printf '[Settings]\n' > "$ini"
	if grep -q '^gtk-theme-name=' "$ini"; then
		sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$name|" "$ini"
	else
		printf 'gtk-theme-name=%s\n' "$name" >> "$ini"
	fi
}
set_ini "$HOME/.config/gtk-3.0/settings.ini"
set_ini "$HOME/.config/gtk-4.0/settings.ini"

# 3) libadwaita / GTK4: do NOT inject the full theme css (it clashes with
# libadwaita's widget styling -- e.g. broken sidebars in nautilus). Instead
# load the rice theme's small color-override file through themes/current.
mkdir -p "$HOME/.config/gtk-4.0"
rm -f "$HOME/.config/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/assets"
[ -L "$HOME/.config/gtk-4.0/gtk.css" ] && rm -f "$HOME/.config/gtk-4.0/gtk.css"
cat > "$HOME/.config/gtk-4.0/gtk.css" <<'EOF'
/* Managed by apply-gtk-theme.sh -- do not edit.
 * libadwaita colors come from the active rice theme; apps read this at
 * launch (theme switches bounce nautilus via apply-icon-theme.sh). */
@import url("../themes/current/gtk4.css");
EOF

# 4) Live re-theme already-running GTK3 apps via xsettingsd (if available).
if command -v xsettingsd >/dev/null 2>&1; then
	conf="$HOME/.config/xsettingsd/xsettingsd.conf"
	mkdir -p "$(dirname "$conf")"
	if [ -f "$conf" ] && grep -q '^Net/ThemeName' "$conf"; then
		sed -i "s|^Net/ThemeName.*|Net/ThemeName \"$name\"|" "$conf"
	else
		printf 'Net/ThemeName "%s"\n' "$name" >> "$conf"
	fi
	if pgrep -x xsettingsd >/dev/null 2>&1; then
		pkill -HUP -x xsettingsd
	else
		setsid xsettingsd >/dev/null 2>&1 < /dev/null &
	fi
fi
