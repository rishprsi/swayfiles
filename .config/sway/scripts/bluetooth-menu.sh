#!/usr/bin/env bash
# Rofi Bluetooth dropdown for the Waybar bluetooth module.
# Requires: bluetoothctl (Ubuntu package: bluez) and rofi.
# Left-click the module to open; select a device to toggle connect/disconnect.

BT=bluetoothctl

if ! command -v "$BT" >/dev/null 2>&1; then
	command -v notify-send >/dev/null 2>&1 &&
		notify-send "Bluetooth menu" "bluetoothctl not found — install 'bluez'."
	exit 1
fi

# Icons via 8-digit \U escapes (avoids UTF-16 surrogate pitfalls in printf).
ICON_ON=$(printf '\U000f00b1')   # bluetooth connected
ICON_OFF=$(printf '\U000f00af')  # bluetooth
ICON_PWR=$(printf '\U000f0425')  # power
ICON_APP=$(printf '\U000f003f')  # cog / manager
DIVIDER="──────────"

powered() { $BT show 2>/dev/null | grep -q "Powered: yes"; }
connected() { $BT info "$1" 2>/dev/null | grep -q "Connected: yes"; }

declare -A MAP

build_menu() {
	local lines="" mac name icon label
	if powered; then
		while read -r _ mac name; do
			[ -z "$mac" ] && continue
			if connected "$mac"; then icon="$ICON_ON"; else icon="$ICON_OFF"; fi
			label="$icon  $name"
			MAP["$label"]="$mac"
			lines+="$label"$'\n'
		done < <($BT devices 2>/dev/null)
		lines+="$DIVIDER"$'\n'"$ICON_PWR  Turn Bluetooth off"$'\n'"$ICON_APP  Open Blueman"
	else
		lines="$ICON_PWR  Turn Bluetooth on"
	fi
	printf '%s' "$lines"
}

choice=$(build_menu | rofi -dmenu -i -p "bluetooth")
[ -z "$choice" ] && exit 0

case "$choice" in
"$DIVIDER") ;;
*"Turn Bluetooth off") $BT power off ;;
*"Turn Bluetooth on")
	rfkill unblock bluetooth 2>/dev/null
	$BT power on
	;;
*"Open Blueman") blueman-manager & ;;
*)
	mac="${MAP[$choice]}"
	[ -z "$mac" ] && exit 0
	if connected "$mac"; then
		$BT disconnect "$mac"
	else
		$BT connect "$mac"
	fi
	;;
esac
