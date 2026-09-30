#!/bin/sh
# Print the first of the given GTK theme names that is installed.
# usage: find-gtk-theme.sh <name>...

for name in "$@"; do
	for base in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes; do
		[ -d "$base/$name" ] && { echo "$name"; exit 0; }
	done
done
exit 1
