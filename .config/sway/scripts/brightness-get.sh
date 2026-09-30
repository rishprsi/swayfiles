#!/bin/sh
# Print current brightness (0-100) of the focused output, for Waybar.
# Laptop panel via brightnessctl; external monitor via a real DDC read,
# which also re-syncs the cache brightness.sh works from (so changes from
# the monitor's physical buttons self-correct).

if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ] && command -v brightnessctl >/dev/null 2>&1; then
	brightnessctl -m | cut -d, -f4 | tr -d %
	exit 0
fi

command -v ddcutil >/dev/null 2>&1 || exit 0

conn=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused) | .name')
bus=""
if [ -n "$conn" ]; then
	ddc=$(readlink /sys/class/drm/card*-"$conn"/ddc 2>/dev/null | head -n1)
	bus="${ddc##*i2c-}"
fi
cache="$HOME/.cache/brightness-${conn:-default}"

# Terse getvcp output: "VCP 10 C <current> <max>"
val=$(ddcutil ${bus:+--bus "$bus"} getvcp 10 --terse 2>/dev/null | awk '{print $4}')

case "$val" in
'' | *[!0-9]*)
	# DDC read failed: fall back to the cached value.
	[ -f "$cache" ] && cat "$cache"
	;;
*)
	mkdir -p "$HOME/.cache"
	printf '%s\n' "$val" >"$cache"
	printf '%s\n' "$val"
	;;
esac
