#!/bin/bash

set -euo pipefail

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi

USERNAME=${SUDO_USER:-$(logname)}
USER_HOME="/home/$USERNAME"

echo -e "\n➡️ Starting full Arch Linux + Hyprland + Utilities + Theming setup script..."

# 1. Update system packages and upgrade
echo "🔄 Updating system packages..."
pacman -Syyu --noconfirm

# 2. Install essential base packages
echo "📦 Installing essential packages..."
pacman -S --noconfirm --needed git base-devel vim nano tar pipewire wireplumber pamixer brightnessctl

# 3. Install Nerd Fonts (simplified selection)
echo "📚 Installing Nerd Fonts..."
pacman -S --noconfirm ttf-cascadia-code-nerd ttf-fira-code ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono

# 4. Install and enable SDDM display manager
echo "🔧 Installing and enabling SDDM display manager..."
pacman -S --noconfirm sddm qt5-graphicaleffects
systemctl enable sddm.service

# Create a Wayland session entry for Hyprland
cat <<EOF > /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Exec=Hyprland
Type=Application
EOF

# 5. Install yay AUR helper if not already present
if [ ! -d "$USER_HOME/yay" ]; then
  echo "🔽 Cloning yay AUR helper..."
  sudo -u "$USERNAME" git clone https://aur.archlinux.org/yay.git "$USER_HOME/yay"
  if cd "$USER_HOME/yay"; then
    echo "📦 Building and installing yay..."
    sudo -u "$USERNAME" makepkg -si --noconfirm
  else
    echo "❌ Failed to enter yay directory."
    exit 1
  fi
  cd - > /dev/null
fi

# 6. Install Brave Browser via yay (AUR)
echo "🌐 Installing Brave Browser..."
sudo -u "$USERNAME" yay -S --noconfirm brave-bin

# 7. Install kitty terminal emulator
echo "🐱 Installing kitty terminal..."
pacman -S --noconfirm kitty

# 8. Install Hyprland and related packages
echo "🎯 Installing Hyprland and related packages..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland polkit-kde-agent dunst qt5-wayland qt6-wayland

# 9. Copy Hyprland configuration file from repo to user config directory
HYPR_CONFIG_SRC="$USER_HOME/arch-linux-setup/configs/hypr/hyprland.conf"
HYPR_CONFIG_DST="$USER_HOME/.config/hypr/hyprland.conf"
if [ ! -f "$HYPR_CONFIG_SRC" ]; then
  echo "❌ Hyprland config not found at $HYPR_CONFIG_SRC"
  exit 1
fi

echo "📁 Copying Hyprland config..."
mkdir -p "$(dirname "$HYPR_CONFIG_DST")"
cp -r "$HYPR_CONFIG_SRC" "$HYPR_CONFIG_DST"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

# 10. Copy Dunst notification daemon config files
DUNST_CONFIG_SRC="$USER_HOME/arch-linux-setup/configs/dunst"
DUNST_CONFIG_DST="$USER_HOME/.config/dunst"
if [ ! -d "$DUNST_CONFIG_SRC" ]; then
  echo "❌ Dunst config not found at $DUNST_CONFIG_SRC"
  exit 1
fi

echo "📁 Copying Dunst config..."
mkdir -p "$DUNST_CONFIG_DST"
cp -r "$DUNST_CONFIG_SRC"/* "$DUNST_CONFIG_DST"
chown -R "$USERNAME:$USERNAME" "$DUNST_CONFIG_DST"

# 11. Enable Traditional Chinese locale zh_TW.UTF-8 alongside English locale
echo "🌐 Enabling zh_TW.UTF-8 locale..."
sed -i 's/^#\(zh_TW\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
if [ -f /etc/locale.conf ]; then
  cp /etc/locale.conf /etc/locale.conf.bak
fi
echo -e "LANG=en_US.UTF-8\nLC_ALL=zh_TW.UTF-8" > /etc/locale.conf

# 12. Install Fcitx5 input method framework and fonts
echo "🈵 Installing Fcitx5 input method and fonts..."
pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

# 13. Create user's .xprofile to export environment variables for Fcitx5
echo "📝 Creating $USER_HOME/.xprofile for Fcitx5 environment variables..."
cat <<'EOF' > "$USER_HOME/.xprofile"
#!/bin/bash
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
export INPUT_METHOD=fcitx5
export MOZ_ENABLE_WAYLAND=1
# Start fcitx5 daemon if not already running
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chown "$USERNAME:$USERNAME" "$USER_HOME/.xprofile"
chmod +x "$USER_HOME/.xprofile"

# 14. Create a startup script to launch fcitx5 on Hyprland start and hook it to Hyprland config
echo "⚙️ Hooking Fcitx5 startup into Hyprland config..."
FCITX_SCRIPT="$USER_HOME/.config/hypr/fcitx.sh"
HCONF="$USER_HOME/.config/hypr/hyprland.conf"

mkdir -p "$(dirname "$FCITX_SCRIPT")"
cp "$USER_HOME/.xprofile" "$FCITX_SCRIPT"
chown "$USERNAME:$USERNAME" "$FCITX_SCRIPT"
chmod +x "$FCITX_SCRIPT"

# Add exec-once line in hyprland.conf if not already present
if [ -f "$HCONF" ] && ! grep -q "exec-once = ~/.config/hypr/fcitx.sh" "$HCONF"; then
  echo "exec-once = ~/.config/hypr/fcitx.sh" >> "$HCONF"
  chown "$USERNAME:$USERNAME" "$HCONF"
fi

# 15. Install utility programs and copy their configuration files
echo "⚙️ Installing utilities and copying configs..."

pacman -S --noconfirm waybar
mkdir -p "$USER_HOME/.config"
cp -r "$USER_HOME/arch-linux-setup/configs/waybar" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/waybar"

sudo -u "$USERNAME" yay -S --noconfirm tofi
cp -r "$USER_HOME/arch-linux-setup/configs/tofi" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/tofi"

pacman -S --noconfirm cliphist

sudo -u "$USERNAME" yay -S --noconfirm swww
mkdir -p "$USER_HOME/.config/assets/backgrounds"
cp -r "$USER_HOME/arch-linux-setup/assets/backgrounds"/* "$USER_HOME/.config/assets/backgrounds/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/assets"

sudo -u "$USERNAME" yay -S --noconfirm hyprpicker

sudo -u "$USERNAME" yay -S --noconfirm hyprlock
mkdir -p "$USER_HOME/.config/hypr"
cp "$USER_HOME/arch-linux-setup/configs/hypr/hyprlock.conf" "$USER_HOME/.config/hypr/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

sudo -u "$USERNAME" yay -S --noconfirm wlogout
mkdir -p "$USER_HOME/.config/wlogout" "$USER_HOME/.config/assets"
cp -r "$USER_HOME/arch-linux-setup/configs/wlogout"/* "$USER_HOME/.config/wlogout/"
cp -r "$USER_HOME/arch-linux-setup/assets/wlogout"/* "$USER_HOME/.config/assets/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/wlogout" "$USER_HOME/.config/assets"

sudo -u "$USERNAME" yay -S --noconfirm grimblast

sudo -u "$USERNAME" yay -S --noconfirm hypridle
cp "$USER_HOME/arch-linux-setup/configs/hypr/hypridle.conf" "$USER_HOME/.config/hypr/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

# 16. Install theming packages and extract themes to system directories
echo "🎨 Installing theming packages and extracting themes..."

pacman -S --noconfirm nwg-look qt5ct qt6ct kvantum

if [ -f "$USER_HOME/arch-linux-setup/assets/themes/Catppuccin-Mocha.tar.xz" ]; then
  tar -xvf "$USER_HOME/arch-linux-setup/assets/themes/Catppuccin-Mocha.tar.xz" -C /usr/share/themes/
else
  echo "❌ Theme archive not found, skipping theme extraction."
fi

if [ -f "$USER_HOME/arch-linux-setup/assets/icons/Tela-circle-dracula.tar.xz" ]; then
  tar -xvf "$USER_HOME/arch-linux-setup/assets/icons/Tela-circle-dracula.tar.xz" -C /usr/share/icons/
else
  echo "❌ Icon archive not found, skipping icon extraction."
fi

sudo -u "$USERNAME" yay -S --noconfirm kvantum-theme-catppuccin-git

cp -r "$USER_HOME/arch-linux-setup/configs/kitty" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/kitty"

# 17. (Optional) Install Neovim and LazyVim config
echo "📚 Installing Neovim and LazyVim..."
pacman -S --noconfirm neovim ripgrep fd lazygit
if [ ! -d "$USER_HOME/.config/nvim" ]; then
  sudo -u "$USERNAME" git clone https://github.com/LazyVim/starter.git "$USER_HOME/.config/nvim"
fi
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/nvim"

# 18. (Optional) Install zsh and oh-my-zsh, then set zsh as default shell
echo "🐚 Installing zsh and oh-my-zsh..."
pacman -S --noconfirm zsh
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
  sudo -u "$USERNAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
chsh -s /bin/zsh "$USERNAME"

# Completion message
echo -e "\n✅ Congratulations! Your Arch Linux setup is complete!"

echo -e "\nRepository Information:"
echo "  - GitHub Repository: https://github.com/gaurav23b/arch-linux-setup"
echo "  - If you found this repo helpful, please consider giving it a star on GitHub!"

echo -e "\nContribute:"
echo "  - Feel free to open issues, submit pull requests, or provide feedback."
echo "  - Every contribution, big or small, is valuable to the community."

echo -e "\nTroubleshooting:"
echo "  - If you encounter any issues, please check the GitHub issues section."
echo "  - Don't hesitate to open a new issue if you can't find a solution to your problem."

echo -e "\nEnjoy your new Hyprland environment!"

echo "------------------------------------------------------------------------"
