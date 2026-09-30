#!/bin/sh
# Keep sway's rice look and GNOME's own look separate on the same account.
#
# Both sessions share the same dconf (gsettings) keys and ~/.config/gtk-4.0,
# so theming one would otherwise restyle the other.
#
#   session-appearance.sh sway    (sway autostart)
#       Snapshot GNOME's appearance keys (unless the sway look is already
#       active), then apply the active rice theme.
#   session-appearance.sh gnome   (~/.config/autostart, GNOME only)
#       Restore the snapshot and remove the files the rice manages.
#
# Change GNOME's look from GNOME Settings/Tweaks as usual: the snapshot is
# retaken at the next sway login.

STATE="$HOME/.local/state/swayfiles"
SNAP="$STATE/gnome-appearance"
MARK="$STATE/sway-appearance-active"
SCHEMA=org.gnome.desktop.interface
KEYS="gtk-theme icon-theme cursor-theme cursor-size color-scheme"

mkdir -p "$STATE"

case "${1:-}" in
sway)
	if [ ! -e "$MARK" ]; then
		tmp="$SNAP.tmp"
		: >"$tmp"
		for k in $KEYS; do
			printf '%s %s\n' "$k" "$(gsettings get "$SCHEMA" "$k")" >>"$tmp"
		done
		mv "$tmp" "$SNAP"
		: >"$MARK"
	fi
	theme="$HOME/.config/themes/current/gtk.sh"
	[ -f "$theme" ] && sh "$theme"
	;;
gnome)
	[ -e "$MARK" ] || exit 0
	if [ -f "$SNAP" ]; then
		while read -r k v; do
			[ -n "$k" ] && gsettings set "$SCHEMA" "$k" "$v"
		done <"$SNAP"
	fi
	# libadwaita color overrides written by apply-gtk-theme.sh
	css="$HOME/.config/gtk-4.0/gtk.css"
	grep -q 'Managed by apply-gtk-theme.sh' "$css" 2>/dev/null && rm -f "$css"
	# XWayland default cursor written by apply-cursor-theme.sh
	idx="$HOME/.local/share/icons/default/index.theme"
	grep -q 'managed-by: swayfiles' "$idx" 2>/dev/null && rm -f "$idx"
	rm -f "$MARK"
	;;
*)
	echo "usage: $0 sway|gnome" >&2
	exit 1
	;;
esac
exit 0
