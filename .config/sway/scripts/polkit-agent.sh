#!/bin/sh
# Start the first installed polkit authentication agent (GUI password
# prompts for NetworkManager, disks, etc.). GNOME has one built in; sway
# needs its own. Ubuntu: apt install mate-polkit (or policykit-1-gnome).

for agent in \
	/usr/libexec/polkit-mate-authentication-agent-1 \
	/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
	/usr/libexec/polkit-gnome-authentication-agent-1 \
	/usr/bin/lxpolkit; do
	[ -x "$agent" ] && exec "$agent"
done
echo "no polkit agent installed (apt install mate-polkit)" >&2
exit 1
