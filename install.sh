#!/bin/sh
# Bootstrap the sway rice on Ubuntu (tested on 26.04), side by side with GNOME.
#
# usage: ./install.sh [--no-packages]
#   --no-packages   skip apt and the session registration (the only sudo parts)
#
# Idempotent: safe to re-run; existing installs/backups are skipped.
# After it finishes: log out, click the gear on the GDM login screen and pick
# "Sway (swayfiles)". Pick "Ubuntu" there to go back to GNOME.

set -u

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SKIP_PACKAGES=0
[ "${1:-}" = "--no-packages" ] && SKIP_PACKAGES=1

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

[ "$(id -u)" -eq 0 ] && {
	warn "run as your user, not root"
	exit 1
}

ICONS="$HOME/.local/share/icons"
mkdir -p "$ICONS" "$HOME/.local/bin" "$HOME/.local/state/swayfiles"

# ---------------------------------------------------------------- packages
if [ "$SKIP_PACKAGES" -eq 0 ]; then
	say "Installing packages (sudo apt)"
	sudo apt-get update -qq
	sudo apt-get install -y --no-install-recommends \
		sway swaybg swaylock swayidle xwayland \
		gtklock gtklock-userinfo-module \
		xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
		waybar sway-notification-center rofi swayosd \
		ghostty nautilus \
		pipewire pipewire-pulse wireplumber pavucontrol \
		cliphist wl-clipboard grim slurp wtype jq \
		playerctl ddcutil brightnessctl libnotify-bin \
		network-manager-applet blueman bluez rfkill \
		mate-polkit gnome-keyring \
		xsettingsd qt6ct qt6-wayland qt6-style-kvantum \
		webp-pixbuf-loader gtk-update-icon-cache xdg-user-dirs \
		sassc libglib2.0-dev-bin libarchive-tools unzip \
		git stow curl ||
		{
			warn "apt failed"
			exit 1
		}

	# Register the session for GDM (system dir; GDM ignores ~/.local).
	say "Registering 'Sway (swayfiles)' login session"
	sudo mkdir -p /usr/local/share/wayland-sessions
	printf '%s\n' \
		'[Desktop Entry]' \
		'Name=Sway (swayfiles)' \
		'Comment=Sway with the swayfiles rice' \
		"Exec=$HOME/.config/sway/session.sh" \
		'Type=Application' \
		'DesktopNames=sway' |
		sudo tee /usr/local/share/wayland-sessions/sway-swayfiles.desktop >/dev/null
else
	say "Skipping packages + session registration (--no-packages)"
fi

# ------------------------------------------------------------------- stow
# Configs previously linked from ~/.ricefiles (the Arch/Hyprland repo) now
# live here; unlink them so the two repos don't fight over ~/.config.
if [ -d "$HOME/.ricefiles" ]; then
	for name in Kvantum qt6ct matugen rofi waybar swaync themes; do
		t="$HOME/.config/$name"
		case "$(readlink "$t" 2>/dev/null)" in
		*/.ricefiles/*)
			warn "unlinking $t (was stowed from ~/.ricefiles)"
			rm -f "$t"
			;;
		esac
	done
fi

say "Linking configs into ~ with stow"
# Back up any real (non-stowed) config dirs that would conflict.
for pkg in "$REPO/.config"/*; do
	name=$(basename "$pkg")
	target="$HOME/.config/$name"
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		backup="$target.pre-sway.$(date +%Y%m%d%H%M%S)"
		warn "backing up existing $target -> $backup"
		mv "$target" "$backup"
	fi
done
mkdir -p "$HOME/.config"
# Run from inside the repo so its .stowrc (ignore list) is honored.
(cd "$REPO" && stow -t "$HOME" -R .) || {
	warn "stow failed"
	exit 1
}

# ---------------------------------------------------------- initial theme
# themes/current is runtime state (gitignored): a relative symlink to one
# theme dir. Repair it if an old script turned it into a real directory.
cur="$REPO/.config/themes/current"
if [ -d "$cur" ] && [ ! -L "$cur" ]; then
	warn "themes/current is a directory, replacing with a symlink"
	rm -rf "$cur"
fi
if [ ! -e "$cur" ]; then
	say "Selecting initial theme: noir"
	ln -sfn noir "$cur"
fi

# ------------------------------------------------------ GNOME side of the switch
# GNOME login: restore GNOME's own GTK/icon/cursor settings (sway changes
# them), see ~/.config/sway/scripts/session-appearance.sh.
mkdir -p "$HOME/.config/autostart"
printf '%s\n' \
	'[Desktop Entry]' \
	'Type=Application' \
	'Name=Restore GNOME appearance (swayfiles)' \
	"Exec=$HOME/.config/sway/scripts/session-appearance.sh gnome" \
	'OnlyShowIn=GNOME;' \
	'NoDisplay=true' \
	>"$HOME/.config/autostart/swayfiles-gnome-appearance.desktop"
# blueman's XDG autostart has no NotShowIn, so it would add a second
# Bluetooth icon to GNOME. Sway starts blueman-applet itself.
if [ -f /etc/xdg/autostart/blueman.desktop ]; then
	sed '/^NotShowIn=/d; /^OnlyShowIn=/d' /etc/xdg/autostart/blueman.desktop >"$HOME/.config/autostart/blueman.desktop"
	printf 'NotShowIn=GNOME;\n' >>"$HOME/.config/autostart/blueman.desktop"
fi
# Ubuntu's waybar/swaync packages enable systemd user units for *every*
# graphical session: they'd start inside GNOME, and in sway they'd run a
# second waybar (without sway's bar IPC) next to the one sway launches.
say "Masking waybar/swaync systemd user units (sway starts its own)"
systemctl --user mask waybar.service swaync.service >/dev/null 2>&1
systemctl --user reset-failed waybar.service swaync.service >/dev/null 2>&1

# -------------------------------------------------------------------- font
# Ubuntu doesn't package Nerd Fonts; waybar/rofi icons need the patched one.
if ! fc-list | grep -qi 'JetBrainsMono Nerd Font'; then
	say "Installing JetBrainsMono Nerd Font into ~/.local/share/fonts"
	tmp=$(mktemp -d)
	mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd"
	curl -fsSL -o "$tmp/f.tar.xz" \
		https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz &&
		tar -xJf "$tmp/f.tar.xz" -C "$HOME/.local/share/fonts/JetBrainsMonoNerd" &&
		fc-cache -f >/dev/null
	rm -rf "$tmp"
else
	say "JetBrainsMono Nerd Font already installed"
fi

# ------------------------------------------------------------- GTK themes
if [ ! -d "$HOME/.themes/Graphite-green-Dark" ] || [ ! -d "$HOME/.themes/Graphite-Dark" ]; then
	say "Building Graphite GTK themes into ~/.themes"
	tmp=$(mktemp -d)
	git clone -q --depth 1 https://github.com/vinceliuice/Graphite-gtk-theme.git "$tmp/g" &&
		"$tmp/g/install.sh" -d "$HOME/.themes" -t green -c dark >/dev/null &&
		"$tmp/g/install.sh" -d "$HOME/.themes" -c dark >/dev/null ||
		warn "Graphite build failed (themes fall back to Yaru/Adwaita dark)"
	rm -rf "$tmp"
else
	say "Graphite GTK themes already installed"
fi

# ------------------------------------------------------------------ icons
# User-local Papirus (not the apt one) so papirus-folders can recolor it
# without sudo.
if [ ! -d "$ICONS/Papirus-Dark" ]; then
	say "Installing Papirus icons into ~/.local/share/icons"
	tmp=$(mktemp -d)
	curl -fsSL https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/heads/master.tar.gz |
		tar xz -C "$tmp" &&
		cp -r "$tmp"/papirus-icon-theme-master/Papirus \
			"$tmp"/papirus-icon-theme-master/Papirus-Dark "$ICONS/"
	rm -rf "$tmp"
else
	say "Papirus icons already installed"
fi

if [ ! -x "$HOME/.local/bin/papirus-folders" ]; then
	say "Installing papirus-folders into ~/.local/bin"
	curl -fsSL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders \
		-o "$HOME/.local/bin/papirus-folders" &&
		chmod +x "$HOME/.local/bin/papirus-folders"
else
	say "papirus-folders already installed"
fi

# ---------------------------------------------------------------- cursors
if [ ! -d "$ICONS/catppuccin-frappe-green-cursors" ]; then
	say "Installing catppuccin cursor variants into ~/.local/share/icons"
	tmp=$(mktemp -d)
	for v in green blue lavender mauve peach yellow red teal sky pink dark; do
		curl -fsSL -o "$tmp/$v.zip" \
			"https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-frappe-$v-cursors.zip" &&
			unzip -qo "$tmp/$v.zip" -d "$ICONS/"
	done
	rm -rf "$tmp"
else
	say "catppuccin cursors already installed"
fi

# Extra cursor themes for the picker (dark variants only).
if [ ! -d "$ICONS/Bibata-Modern-Classic" ]; then
	say "Installing extra cursor themes into ~/.local/share/icons"
	tmp=$(mktemp -d)
	for url in \
		"https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" \
		"https://github.com/rose-pine/cursors/releases/download/v1.1.0/BreezeX-RosePine-Linux.tar.xz" \
		"https://github.com/guillaumeboehm/Nordzy-cursors/releases/download/v2.4.0/Nordzy-cursors.tar.gz"; do
		curl -fsSL -o "$tmp/pkg" "$url" && bsdtar -xf "$tmp/pkg" -C "$ICONS/"
	done
	# Future-cursors has no releases; prebuilt theme lives in the repo's dist/.
	curl -fsSL "https://github.com/yeyushengfan258/Future-cursors/archive/refs/heads/master.tar.gz" |
		bsdtar -xf - -C "$tmp" &&
		mkdir -p "$ICONS/Future-cursors" &&
		cp -r "$tmp"/Future-cursors-master/dist/* "$ICONS/Future-cursors/"
	rm -rf "$tmp"
	# Nordzy tarball ships index.theme without a Name= field; normalize.
	[ -d "$ICONS/Nordzy-cursors" ] &&
		printf '[Icon Theme]\nName=Nordzy-cursors\nComment=Nordzy cursor theme\n' \
			>"$ICONS/Nordzy-cursors/index.theme"
else
	say "extra cursor themes already installed"
fi

# ---------------------------------------------------------------- matugen
# Optional: powers the wallpaper-generated "auto" theme. Not in apt.
if ! command -v matugen >/dev/null 2>&1; then
	if command -v cargo >/dev/null 2>&1; then
		say "Installing matugen with cargo (auto theme)"
		cargo install --locked matugen >/dev/null 2>&1 || warn "cargo install matugen failed (auto theme disabled)"
	else
		warn "matugen not installed: the 'auto' theme is hidden until it is"
	fi
fi

# ------------------------------------------------------------------ checks
if command -v sway >/dev/null 2>&1; then
	if sway -C >/dev/null 2>&1; then
		say "sway config OK"
	else
		warn "sway config has errors:"
		sway -C 2>&1 | grep -i error >&2
	fi
fi

say "Done."
printf '%s\n' \
	"" \
	"Next steps:" \
	"  1. Log out. On the GDM login screen click the gear icon and pick" \
	"     'Sway (swayfiles)'. Pick 'Ubuntu' to go back to GNOME; GNOME's own" \
	"     theme/icons/cursor are restored automatically on that login." \
	"  2. Super+Shift+T theme, Super+Shift+W wallpaper, Super+B show/hide the bar." \
	"  3. Ghostty config is NOT managed here -- to follow the theme, add to" \
	"     ~/.config/ghostty/config:" \
	"       config-file = ?$HOME/.config/themes/current/ghostty.conf" \
	"  4. External-monitor brightness uses DDC/CI (ddcutil). Its udev rule" \
	"     applies after a reboot (or: sudo udevadm trigger)."
