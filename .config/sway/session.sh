#!/bin/sh
# Login-manager entry point for the rice sway session. install.sh registers
# it as "Sway (swayfiles)" in /usr/local/share/wayland-sessions, so GDM's
# gear menu offers it next to Ubuntu/GNOME.
#
# Exports ~/.config/sway/env, runs sway, and on exit tears down the bits of
# the systemd --user environment sway exported, so a following GNOME login
# (without a reboot) starts clean.

# GDM doesn't always run a login shell for non-GNOME sessions.
for d in "$HOME/.local/bin" "$HOME/.cargo/bin" /snap/bin; do
	case ":$PATH:" in *":$d:"*) ;; *) [ -d "$d" ] && PATH="$PATH:$d" ;; esac
done
export PATH

set -a
# shellcheck source=/dev/null
[ -f "$HOME/.config/sway/env" ] && . "$HOME/.config/sway/env"
set +a

log() { printf 'session.sh: %s\n' "$*" | systemd-cat --identifier=sway 2>/dev/null; }

# GDM (50, Ubuntu 26.04) keeps its greeter running -- and holding the GPU as
# DRM master -- until the new session registers its display, which GNOME
# Shell does itself. Sway doesn't, so it would fail with "Could not take
# device: Device or resource busy" and drop straight back to the login
# screen. Register on sway's behalf, then wait for the greeter to go away.
if command -v gdbus >/dev/null 2>&1; then
	for m in RegisterSession RegisterDisplay; do
		gdbus call --system --dest org.gnome.DisplayManager \
			--object-path /org/gnome/DisplayManager/Manager \
			--method "org.gnome.DisplayManager.Manager.$m" >/dev/null 2>&1 ||
			log "GDM $m failed (not started by GDM?)"
	done
fi
greeter_running() {
	loginctl list-sessions --no-legend 2>/dev/null | awk '$6 == "greeter" { f = 1 } END { exit !f }'
}
i=0
while greeter_running && [ "$i" -lt 50 ]; do # up to ~10s
	sleep 0.2
	i=$((i + 1))
done
greeter_running && log "greeter still running after 10s, starting sway anyway"

run_sway() {
	if command -v systemd-cat >/dev/null 2>&1; then
		systemd-cat --identifier=sway sway "$@" # logs: journalctl --user -t sway
	else
		sway "$@"
	fi
}

# Safety net: if sway dies right away (GPU still busy), retry a few times
# instead of bouncing back to GDM.
tries=0
while :; do
	start=$(date +%s)
	run_sway "$@"
	status=$?
	tries=$((tries + 1))
	[ "$status" -eq 0 ] && break
	[ $(($(date +%s) - start)) -ge 5 ] && break # ran for a while: real exit/crash
	[ "$tries" -ge 5 ] && break
	log "sway exited early (status $status), retrying ($tries/5)"
	sleep 1
done

# Portals/services started under sway would otherwise keep sway's
# XDG_CURRENT_DESKTOP if GNOME is started from the same user manager.
systemctl --user stop xdg-desktop-portal.service xdg-desktop-portal-wlr.service \
	xdg-desktop-portal-gtk.service 2>/dev/null
systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY SWAYSOCK \
	XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null
exit $status
