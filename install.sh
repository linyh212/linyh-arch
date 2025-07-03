#!/bin/bash

# Exit immediately if any command fails
set -e

# GitHub repository containing your Hyprland config
CONFIG_REPO="https://github.com/linyh212/linyh-arch"

# Local paths for config and temporary clone
CONFIG_DIR="$HOME/.config"
TEMP_DIR="$HOME/temp-hypr-config"

echo "🌀 Updating system..."
# Update system packages
sudo pacman -Syu --noconfirm

echo "📦 Installing base packages..."
# Essential system, terminal, and desktop packages
packages=(
  base-devel git curl wget unzip zip
  zsh neovim kitty thunar file-roller
  xdg-desktop-portal-hyprland waybar wofi dunst swww
  wl-clipboard grim slurp swappy
  brightnessctl pamixer
  pavucontrol pipewire wireplumber
  network-manager-applet blueman bluez bluez-utils
  noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd
  gvfs tumbler ffmpegthumbnailer
  polkit-kde-agent
)

# Install packages if not already present
for pkg in "${packages[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    echo "➡️  Installing $pkg..."
    sudo pacman -S --noconfirm "$pkg"
  else
    echo "✅ $pkg is already installed, skipping."
  fi
done

echo "🔧 Installing yay (AUR helper)..."
# Install yay if not installed
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay && makepkg -si --noconfirm
  cd ~ && rm -rf ~/yay
else
  echo "✅ yay is already installed, skipping."
fi

echo "✨ Installing Hyprland AUR tools..."
# AUR packages for extended Hyprland functionality
aur_packages=(
  hyprpaper hypridle hyprlock
  wlogout swaylock-effects-git nwg-look
)

# Install AUR packages via yay if not already present
for pkg in "${aur_packages[@]}"; do
  if ! yay -Qi "$pkg" &>/dev/null; then
    yay -S --noconfirm "$pkg"
  else
    echo "✅ $pkg is already installed, skipping."
  fi
done

echo "🖥️ Setting Zsh as default shell..."
# Change shell to zsh if not already set
if [ "$SHELL" != "/bin/zsh" ]; then
  chsh -s /bin/zsh
else
  echo "✅ Zsh is already the default shell, skipping."
fi

echo "💡 Installing Oh My Zsh..."
# Install Oh My Zsh framework if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh is already installed, skipping."
fi

echo "📁 Cloning Hyprland config from GitHub..."
# Clean previous temp folder if exists
if [ -d "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
fi

echo "📁 Cloning Hyprland config from GitHub..."
if [ -d "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
fi

# Clone the repo that contains /configs/ folder
git clone --depth=1 "$CONFIG_REPO" "$TEMP_DIR"

echo "🔃 Backing up old configs (if any)..."
for folder in hypr hypridle wlogout; do
  if [ -d "$CONFIG_DIR/$folder" ]; then
    mv "$CONFIG_DIR/$folder" "$CONFIG_DIR/${folder}.backup.$(date +%s)"
  fi
done

echo "📦 Copying configs to ~/.config..."
mkdir -p "$CONFIG_DIR"
cp -r "$TEMP_DIR/configs/dunst" "$CONFIG_DIR/"
cp -r "$TEMP_DIR/configs/hypr" "$CONFIG_DIR/"
cp -r "$TEMP_DIR/configs/kitty" "$CONFIG_DIR/"
cp -r "$TEMP_DIR/configs/tofi" "$CONFIG_DIR/"
cp -r "$TEMP_DIR/configs/waybar" "$CONFIG_DIR/"
cp -r "$TEMP_DIR/configs/wlogout" "$CONFIG_DIR/"
rm -rf "$TEMP_DIR"
