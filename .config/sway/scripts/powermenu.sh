#!/bin/sh
# Rofi power menu for the Waybar power button.

# Nerd Font icons as octal UTF-8 bytes: /bin/sh is dash here, and dash's
# printf only understands octal escapes (\U / \x are printed literally).
#   lock U+F033E  logout U+F0343  suspend U+F04B2  reboot U+F0709  power U+F0425
choice=$(printf '\363\260\214\276  Lock\n\363\260\215\203  Logout\n\363\260\222\262  Suspend\n\363\260\234\211  Reboot\n\363\260\220\245  Shutdown' |
	rofi -dmenu -i -p "power")

case "$choice" in
*Lock) "$HOME/.config/sway/scripts/lock.sh" ;;
*Logout) swaymsg exit ;;
*Suspend) systemctl suspend ;;
*Reboot) systemctl reboot ;;
*Shutdown) systemctl poweroff ;;
esac
