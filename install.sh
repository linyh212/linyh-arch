#!/bin/bash

set -e  # Exit immediately if any command fails

# URL of your GitHub repo containing Hyprland config files
CONFIG_REPO="https://github.com/linyh212/linyh-arch"

# Define config and temporary directories
CONFIG_DIR="$HOME/.config"
TEMP_DIR="$HOME/temp-hypr-config"

echo "🌀 Updating system..."
# Fully update the system packages to latest versions
sudo pacman -Syu --noconfirm

echo "📦 Installing essential packages..."
# List of required base packages and utilities for Hyprland environment
packages=(
  base-devel git curl wget unzip zip                  # Development tools and utilities
  zsh neovim kitty thunar file-roller                 # Shell, editor, terminal emulator, file manager
  xdg-desktop-portal-hyprland waybar wofi dunst swww  # Desktop portal, status bar, app launcher, notifications, wallpaper
  wl-clipboard grim slurp swappy                      # Wayland clipboard, screenshot tools, image annotator
  brightnessctl pamixer                               # Backlight and audio volume control
  pavucontrol pipewire wireplumber                    # Audio system and session managers
  network-manager-applet blueman bluez bluez-utils    # Networking and Bluetooth management
  noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd   # Fonts including Chinese and patched Nerd fonts
  gvfs tumbler ffmpegthumbnailer                      # Virtual filesystem and thumbnails support
  polkit-kde-agent                                    # Polkit authentication agent for GUI
)

# Install each package only if it's not already installed
for pkg in "${packages[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    echo "➡️ Installing $pkg..."
    sudo pacman -S --noconfirm "$pkg"
  else
    echo "✅ $pkg is already installed."
  fi
done

echo "🔧 Installing yay (AUR helper)..."
# Install yay from AUR if not present to manage AUR packages easily
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay && makepkg -si --noconfirm
  cd ~ && rm -rf ~/yay
else
  echo "✅ yay is already installed."
fi

echo "✨ Installing Hyprland AUR tools..."
# Additional AUR packages that enhance Hyprland functionality
aur_packages=(
  hyprpaper hypridle hyprlock                   # Wallpaper manager, idle handler, screen locker
  wlogout swaylock-effects-git nwg-look          # Logout menu, lock screen effects, GTK theme switcher
)

# Install each AUR package via yay if missing
for pkg in "${aur_packages[@]}"; do
  if ! yay -Qi "$pkg" &>/dev/null; then
    yay -S --noconfirm "$pkg"
  else
    echo "✅ $pkg is already installed."
  fi
done

echo "🖥️ Setting Zsh as default shell..."
# Change default shell to Zsh if not already set
if [ "$SHELL" != "/bin/zsh" ]; then
  chsh -s /bin/zsh
  echo "⚠️ Please log out and log back in for Zsh shell to activate."
else
  echo "✅ Zsh is already the default shell."
fi

echo "💡 Installing Oh My Zsh..."
# Install Oh My Zsh framework if not installed for better shell experience
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh is already installed."
fi

echo "📁 Cloning Hyprland config from GitHub..."
# Remove any existing temporary folder and clone config repo freshly
rm -rf "$TEMP_DIR"
git clone --depth=1 "$CONFIG_REPO" "$TEMP_DIR"

# Verify that expected config folder exists in cloned repo
if [ ! -d "$TEMP_DIR/configs/hypr" ]; then
  echo "❌ Config folder not found in repo. Exiting."
  exit 1
fi

echo "🔃 Backing up old configs..."
# Backup any existing Hyprland-related config folders before overwriting
for folder in hypr hypridle wlogout kitty waybar dunst tofi; do
  if [ -d "$CONFIG_DIR/$folder" ]; then
    mv "$CONFIG_DIR/$folder" "$CONFIG_DIR/${folder}.backup.$(date +%s)"
  fi
done

echo "📦 Copying configs to ~/.config..."
# Copy new config files from cloned repo to user's config directory
cp -r "$TEMP_DIR/configs/"* "$CONFIG_DIR/"
rm -rf "$TEMP_DIR"

echo "🛜 Enabling essential system services..."
# Enable Bluetooth and NetworkManager services immediately and on boot
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now NetworkManager.service

# Enable PipeWire audio user services for current user
sudo systemctl --user enable --now pipewire.service
sudo systemctl --user enable --now wireplumber.service

echo "🛠 Installing greetd, tuigreet, and seatd for graphical login..."
# Install greetd login manager and related tools for Wayland-compatible login screen
sudo pacman -S --noconfirm greetd greetd-tuigreet seatd

echo "🚀 Enabling greetd and seatd systemd services..."
sudo systemctl enable greetd
sudo systemctl enable seatd
sudo systemctl start seatd
sudo systemctl start greetd

# Create 'greeter' system user for greetd if not existing
if id -u greeter &>/dev/null; then
  echo "✅ User 'greeter' already exists."
else
  echo "👤 Creating user 'greeter'..."
  sudo useradd -M -G seat -s /usr/bin/nologin greeter
fi

GREETD_CONFIG="/etc/greetd/config.toml"

echo "📝 Writing greetd configuration to $GREETD_CONFIG..."
# Setup greetd config to launch tuigreet login with Hyprland session by default
sudo tee "$GREETD_CONFIG" > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland --user-menu --remember --time --asterisks"
user = "greeter"
EOF

echo "✅ greetd login manager setup complete."

echo "✅ All done! Please reboot your system to start using Hyprland with greetd login manager."
