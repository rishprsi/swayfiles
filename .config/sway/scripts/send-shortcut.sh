#!/bin/sh
# Forward Cmd+<key> to the focused app as Ctrl+<key> (macOS muscle memory).
# Terminals use Ctrl+Shift+C/V for copy/paste (Ctrl+C is SIGINT), so those
# two get the shifted variant when a terminal is focused.
# usage: send-shortcut.sh <key> [shift]

key="$1"
[ -n "$key" ] || exit 1

app=$(swaymsg -t get_tree |
	jq -r 'first(.. | select(.focused? == true)) | .app_id // .window_properties.class // ""')

shift_mod="${2:-}"
case "$key" in
c | v)
	case "$app" in
	com.mitchellh.ghostty | *ghostty* | foot | footclient | kitty | Alacritty | \
		org.wezfurlong.wezterm | org.gnome.Terminal | org.gnome.Ptyxis | \
		gnome-terminal-server | xterm | XTerm)
		shift_mod=shift
		;;
	esac
	;;
esac

if [ -n "$shift_mod" ]; then
	exec wtype -M ctrl -M shift -k "$key" -m shift -m ctrl
else
	exec wtype -M ctrl -k "$key" -m ctrl
fi
