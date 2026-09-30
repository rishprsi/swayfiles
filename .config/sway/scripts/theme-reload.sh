#!/bin/sh
# Restyle every running app from the active theme (themes/current).
# Used by theme-switch.sh and by set-wallpaper.sh (auto theme).

# Borders (themes/current/sway.conf). Sway also restarts waybar
# (swaybar_command), which re-reads its CSS.
swaymsg reload >/dev/null 2>&1

swaync-client -rs >/dev/null 2>&1 # notification css

# Ghostty >= 1.2 reloads its config on SIGUSR2.
pkill -USR2 -x ghostty 2>/dev/null

# rofi and swaylock read their colors at launch -- nothing to reload.
exit 0
