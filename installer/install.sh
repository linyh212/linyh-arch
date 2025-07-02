#!/bin/bash

set -e
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi
USERNAME=${SUDO_USER:-$(logname)}
USER_HOME="/home/$USERNAME"
echo -e "\n➡️ Starting full Arch Linux + Hyprland + Utilities + Theming setup script..."

# 1. 系統更新與安裝基本套件
echo "🔄 Updating system packages..."
pacman -Syyu --noconfirm
echo "📦 Installing essential packages..."
pacman -S --noconfirm --needed git base-devel vim nano tar pipewire wireplumber pamixer brightnessctl

# 2. 安裝 Nerd Fonts
echo "📚 Installing Nerd Fonts..."
pacman -S --noconfirm ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono

# 3. 安裝 SDDM 並啟用
echo "🔧 Installing and enabling SDDM display manager..."
pacman -S --noconfirm sddm
systemctl enable sddm.service

# 4. 安裝 yay (AUR helper)
if [ ! -d "$USER_HOME/yay" ]; then
  echo "🔽 Cloning yay AUR helper..."
  sudo -u "$USERNAME" git clone https://aur.archlinux.org/yay.git "$USER_HOME/yay"
  pushd "$USER_HOME/yay" > /dev/null
  echo "📦 Building and installing yay..."
  sudo -u "$USERNAME" makepkg -si --noconfirm
  popd > /dev/null
fi

# 5. 安裝 Brave 瀏覽器
echo "🌐 Installing Brave Browser..."
sudo -u "$USERNAME" yay -S --noconfirm brave-bin

# 6. 安裝 kitty 終端機
echo "🐱 Installing kitty terminal..."
pacman -S --noconfirm kitty

# 7. 安裝 Hyprland 及相關套件
echo "🎯 Installing Hyprland and related packages..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland polkit-kde-agent dunst qt5-wayland qt6-wayland

# 8. 複製 hyprland 配置檔
HYPR_CONFIG_SRC="$USER_HOME/simple-hyprland/configs/hypr/hyprland.conf"
HYPR_CONFIG_DST="$USER_HOME/.config/hypr/hyprland.conf"
echo "📁 Copying Hyprland config..."
mkdir -p "$(dirname "$HYPR_CONFIG_DST")"
cp -r "$HYPR_CONFIG_SRC" "$HYPR_CONFIG_DST"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

# 9. 複製 dunst 配置
DUNST_CONFIG_SRC="$USER_HOME/simple-hyprland/configs/dunst"
DUNST_CONFIG_DST="$USER_HOME/.config/dunst"
echo "📁 Copying Dunst config..."
mkdir -p "$DUNST_CONFIG_DST"
cp -r "$DUNST_CONFIG_SRC"/* "$DUNST_CONFIG_DST"
chown -R "$USERNAME:$USERNAME" "$DUNST_CONFIG_DST"

# 10. 啟用 zh_TW.UTF-8 locale
echo "🌐 Enabling zh_TW.UTF-8 locale..."
sed -i 's/^#\(zh_TW\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
if [ -f /etc/locale.conf ]; then
  cp /etc/locale.conf /etc/locale.conf.bak
fi
echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" > /etc/locale.conf

# 11. 安裝 Fcitx5 與字體
echo "🈵 Installing Fcitx5 input method and fonts..."
pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

# 12. 建立 ~/.xprofile 設定輸入法環境變數
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
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chown "$USERNAME:$USERNAME" "$USER_HOME/.xprofile"
chmod +x "$USER_HOME/.xprofile"

# 13. 建立 Hyprland 啟動腳本並 hook Fcitx5
echo "⚙️ Hooking Fcitx5 startup into Hyprland config..."
FCITX_SCRIPT="$USER_HOME/.config/hypr/fcitx.sh"
HCONF="$USER_HOME/.config/hypr/hyprland.conf"
mkdir -p "$(dirname "$FCITX_SCRIPT")"
cp "$USER_HOME/.xprofile" "$FCITX_SCRIPT"
chown "$USERNAME:$USERNAME" "$FCITX_SCRIPT"
chmod +x "$FCITX_SCRIPT"
if [ -f "$HCONF" ] && ! grep -q "exec-once = ~/.config/hypr/fcitx.sh" "$HCONF"; then
  echo "exec-once = ~/.config/hypr/fcitx.sh" >> "$HCONF"
  chown "$USERNAME:$USERNAME" "$HCONF"
fi

# 14. 安裝 Utilities & 複製設定檔
echo "⚙️ Installing utilities and copying configs..."

pacman -S --noconfirm waybar
mkdir -p "$USER_HOME/.config"
cp -r "$USER_HOME/simple-hyprland/configs/waybar" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/waybar"

sudo -u "$USERNAME" yay -S --noconfirm tofi
cp -r "$USER_HOME/simple-hyprland/configs/tofi" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/tofi"

pacman -S --noconfirm cliphist

sudo -u "$USERNAME" yay -S --noconfirm swww
mkdir -p "$USER_HOME/.config/assets/backgrounds"
cp -r "$USER_HOME/simple-hyprland/assets/backgrounds"/* "$USER_HOME/.config/assets/backgrounds/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/assets"

sudo -u "$USERNAME" yay -S --noconfirm hyprpicker

sudo -u "$USERNAME" yay -S --noconfirm hyprlock
mkdir -p "$USER_HOME/.config/hypr"
cp "$USER_HOME/simple-hyprland/configs/hypr/hyprlock.conf" "$USER_HOME/.config/hypr/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

sudo -u "$USERNAME" yay -S --noconfirm wlogout
mkdir -p "$USER_HOME/.config/wlogout" "$USER_HOME/.config/assets"
cp -r "$USER_HOME/simple-hyprland/configs/wlogout"/* "$USER_HOME/.config/wlogout/"
cp -r "$USER_HOME/simple-hyprland/assets/wlogout"/* "$USER_HOME/.config/assets/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/wlogout" "$USER_HOME/.config/assets"

sudo -u "$USERNAME" yay -S --noconfirm grimblast

sudo -u "$USERNAME" yay -S --noconfirm hypridle
cp "$USER_HOME/simple-hyprland/configs/hypr/hypridle.conf" "$USER_HOME/.config/hypr/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/hypr"

# 15. Theming 部分安裝與解壓
echo "🎨 Installing theming packages and extracting themes..."

pacman -S --noconfirm nwg-look
pacman -S --noconfirm qt5ct qt6ct kvantum

tar -xvf "$USER_HOME/simple-hyprland/assets/themes/Catppuccin-Mocha.tar.xz" -C /usr/share/themes/
tar -xvf "$USER_HOME/simple-hyprland/assets/icons/Tela-circle-dracula.tar.xz" -C /usr/share/icons/

sudo -u "$USERNAME" yay -S --noconfirm kvantum-theme-catppuccin-git

cp -r "$USER_HOME/simple-hyprland/configs/kitty" "$USER_HOME/.config/"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/kitty"

# 16. 完成訊息
echo -e "\n✅ Congratulations! Your Simple Hyprland setup is complete!"

echo -e "\nRepository Information:"
echo "  - GitHub Repository: https://github.com/gaurav23b/simple-hyprland"
echo "  - If you found this repo helpful, please consider giving it a star on GitHub!"

echo -e "\nContribute:"
echo "  - Feel free to open issues, submit pull requests, or provide feedback."
echo "  - Every contribution, big or small, is valuable to the community."

echo -e "\nTroubleshooting:"
echo "  - If you encounter any issues, please check the GitHub issues section."
echo "  - Don't hesitate to open a new issue if you can't find a solution to your problem."

echo -e "\nEnjoy your new Hyprland environment!"

echo "------------------------------------------------------------------------"