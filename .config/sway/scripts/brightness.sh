#!/bin/sh
# Adjust brightness of the focused output.
#   laptop panel (/sys/class/backlight) -> brightnessctl
#   external monitor                    -> DDC/CI via ddcutil
#
# usage: brightness.sh <+|-> [step]      e.g. brightness.sh + 10
#
# DDC writes are slow (~200ms over i2c), so the OSD and cache update
# instantly from a computed value and the hardware write happens in the
# background. brightness-get.sh re-syncs the cache with the real value
# whenever Waybar refreshes (signal RTMIN+9 below).

op="$1"
step="${2:-10}"
if [ "$op" != "+" ] && [ "$op" != "-" ]; then
	echo "usage: $0 <+|-> [step]" >&2
	exit 1
fi

osd() { # $1 = 0-100
	swayosd-client --custom-progress "$(awk "BEGIN{print $1/100}")" \
		--custom-icon display-brightness-symbolic >/dev/null 2>&1 ||
		notify-send -a brightness -t 1000 -h int:value:"$1" \
			-h string:x-canonical-private-synchronous:brightness "Brightness" "$1%"
}

# Internal panel: brightnessctl handles permissions via logind/udev.
if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ] && command -v brightnessctl >/dev/null 2>&1; then
	brightnessctl -q set "${step}%${op}"
	pct=$(brightnessctl -m | cut -d, -f4 | tr -d %)
	osd "$pct"
	pkill -RTMIN+9 -x waybar
	exit 0
fi

command -v ddcutil >/dev/null 2>&1 || { notify-send "Brightness" "ddcutil not installed"; exit 1; }

# Connector name of the focused output, e.g. HDMI-A-1 (same name as DRM).
conn=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused) | .name')

# The kernel exposes each connector's DDC channel as a symlink to its i2c bus,
# e.g. /sys/class/drm/card1-HDMI-A-1/ddc -> ../../../i2c-1
bus=""
if [ -n "$conn" ]; then
	ddc=$(readlink /sys/class/drm/card*-"$conn"/ddc 2>/dev/null | head -n1)
	bus="${ddc##*i2c-}"
fi

mkdir -p "$HOME/.cache"
cache="$HOME/.cache/brightness-${conn:-default}"

# Current value: cache first (instant); fall back to one real DDC read.
cur=""
[ -f "$cache" ] && cur=$(cat "$cache" 2>/dev/null)
case "$cur" in
'' | *[!0-9]*)
	cur=$(ddcutil ${bus:+--bus "$bus"} getvcp 10 --terse 2>/dev/null | awk '{print $4}')
	;;
esac
case "$cur" in '' | *[!0-9]*) cur=50 ;; esac

if [ "$op" = "+" ]; then new=$((cur + step)); else new=$((cur - step)); fi
[ "$new" -gt 100 ] && new=100
[ "$new" -lt 0 ] && new=0
printf '%s\n' "$new" >"$cache"

osd "$new" &

(
	ddcutil ${bus:+--bus "$bus"} --noverify setvcp 10 "$new" >/dev/null 2>&1
	pkill -RTMIN+9 -x waybar
) &
