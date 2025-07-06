#!/bin/bash
set -euo pipefail

log() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# 1. Install essential tools and yay
log "Installing essential packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel vim

if ! command -v yay &>/dev/null; then
  log "Installing yay..."
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay
  makepkg -si --noconfirm
  cd ~
fi

# 2. Install Hyprland and core packages
log "Installing Hyprland and related packages..."
yay -S --noconfirm hyprland

sudo pacman -S --noconfirm \
  qt5-wayland qt6-wayland xwayland \
  xdg-desktop-portal-hyprland xdg-utils gvfs polkit-kde-agent \
  pipewire pipewire-audio wireplumber \
  vim nano wget htop openssh smartmontools \
  kitty dolphin firefox \
  dunst grim slurp \
  wofi waybar

# 3. Clone custom install scripts (optional)
log "Cloning and running custom install scripts..."
git clone https://github.com/linyh212/linyh-arch.git ~/linyh-arch
cd ~/linyh-arch
chmod +x install.sh
./install.sh
cd ~

# 4. Locale settings
log "Configuring zh_TW locale..."
sudo sed -i 's/^#zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" | sudo tee /etc/locale.conf

# 5. Install Fcitx5 with Chewing (Chinese Input)
log "Installing fcitx5-chewing..."
sudo pacman -S --noconfirm fcitx5-im fcitx5-chewing

log "Configuring input method environment variables..."
cat <<EOF > ~/.xprofile
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
export INPUT_METHOD=fcitx5
export MOZ_ENABLE_WAYLAND=1
EOF

# 6. Install desktop enhancements
log "Installing desktop tools (hyprpaper, hyprlock, etc.)..."
yay -S --noconfirm \
  hyprpaper hyprlock hypridle wlogout nwg-look fastfetch ttf-jetbrains-mono-nerd

# 7. Configure Hyprland auto-start
log "Configuring Hyprland auto-start programs..."
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$(dirname "$HYPR_CONF")"
touch "$HYPR_CONF"

for line in \
  "exec-once = fcitx5" \
  "exec-once = hyprpaper" \
  "exec-once = hypridle" \
  "exec-once = dunst" \
  "exec-once = polkit-kde-authentication-agent-1"; do
  grep -qxF "$line" "$HYPR_CONF" || echo "$line" >> "$HYPR_CONF"
done

log "✅ Hyprland setup complete. Please reboot or relogin to start using the environment."
