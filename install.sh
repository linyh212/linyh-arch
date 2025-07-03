#!/bin/bash
set -e

echo "📡 Connecting to network: Make sure you're connected before running this script."

# 🔧 Install basic packages and development tools
echo "🔧 Installing base-devel, git, vim..."
sudo pacman -Syu --noconfirm base-devel git vim

# 🔧 Install yay (AUR helper)
echo "📦 Installing yay..."
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo "✅ Base system and yay installed."

# 🖥️ Install Hyprland (using JaKooLit script)
echo "🖥️ Cloning Hyprland setup script..."
git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd ~/Arch-Hyprland
chmod +x install.sh
./install.sh

# 🌐 Locale settings for Traditional Chinese
echo "🌐 Configuring locale for zh_TW..."
sudo sed -i 's/#zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" | sudo tee /etc/locale.conf

# ⌨️ Install fcitx5 with Chewing (注音)
echo "⌨️ Installing Fcitx5 and Chewing..."
sudo pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt \
  fcitx5-configtool fcitx5-chewing

# 🔠 Install fonts
echo "🔤 Installing fonts..."
sudo pacman -S --noconfirm noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

# ⚙️ Add fcitx5 startup script
echo "⚙️ Creating Fcitx5 environment script..."
mkdir -p ~/.config/hypr
cat <<'EOF' > ~/.config/hypr/fcitx.sh
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
chmod +x ~/.config/hypr/fcitx.sh

# 🧩 Add to Hyprland config
echo "🧩 Updating Hyprland config to run fcitx..."
HYP_CONFIG=~/.config/hypr/hyprland.conf
if ! grep -q 'exec-once = ~/.config/hypr/fcitx.sh' "$HYP_CONFIG"; then
    echo 'exec-once = ~/.config/hypr/fcitx.sh' >> "$HYP_CONFIG"
fi

echo "✅ Hyprland and input method configured. Run 'fcitx5-configtool' to set input method."