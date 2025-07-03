#!/bin/bash
set -e

echo "🔧 Updating system and installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git vim

echo "📦 Installing yay AUR helper..."
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~
rm -rf yay

echo "🌏 Setting Traditional Chinese locale..."
sudo sed -i 's/^#\(zh_TW.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sudo locale-gen
echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf
echo 'LC_CTYPE=zh_TW.UTF-8' | sudo tee -a /etc/locale.conf

echo "🖥 Installing Hyprland and related desktop tools..."
sudo pacman -S --noconfirm \
  hyprland xdg-desktop-portal-hyprland \
  kitty waybar wofi rofi \
  thunar thunar-archive-plugin file-roller \
  firefox neofetch grim slurp wl-clipboard \
  swaylock swayidle pamixer pavucontrol \
  pipewire pipewire-pulse wireplumber

echo "⌨️ Installing fcitx5 and Chewing input method..."
sudo pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing

echo "📝 Writing ~/.xprofile with fcitx5 environment variables..."
cat <<EOF > ~/.xprofile
#!/bin/bash
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
export INPUT_METHOD=fcitx5
export MOZ_ENABLE_WAYLAND=1
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chmod +x ~/.xprofile

echo "💡 Configuring Hyprland to auto-launch fcitx5..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/fcitx.sh
#!/bin/bash
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chmod +x ~/.config/hypr/fcitx.sh

# Append to hyprland.conf only if not already present
CONF=~/.config/hypr/hyprland.conf
if [ -f "\$CONF" ]; then
  grep -q 'exec-once = ~/.config/hypr/fcitx.sh' "\$CONF" || echo 'exec-once = ~/.config/hypr/fcitx.sh' >> "\$CONF"
fi

echo "🖋 Installing fonts for CJK and UI..."
sudo pacman -S --noconfirm noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

echo "✅ All done! Reboot to enter your Hyprland environment!"
