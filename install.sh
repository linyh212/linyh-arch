#!/bin/bash
set -e

echo "📡 Connecting to network: Make sure you're connected before running this script."

# 🔧 Install base-devel, git, vim if not installed
echo "🔧 Checking for base-devel, git, vim..."
sudo pacman -Syu --noconfirm
for pkg in base-devel git vim; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    else
        echo "$pkg already installed. Skipping..."
    fi
done

# 🔧 Install yay (AUR helper)
if ! command -v yay &>/dev/null; then
    echo "📦 Installing yay..."
    cd ~
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf yay
else
    echo "📦 yay already installed. Skipping..."
fi

echo "✅ Base system and yay installed."

# 🖥️ Install Hyprland (using JaKooLit script)
if ! command -v Hyprland &>/dev/null; then
    echo "🖥️ Installing Hyprland..."
    git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
    cd ~/Arch-Hyprland
    chmod +x install.sh
    ./install.sh
else
    echo "🖥️ Hyprland already installed. Skipping..."
fi

# 🌐 Locale settings for Traditional Chinese
echo "🌐 Configuring locale for zh_TW..."
if ! grep -q '^zh_TW.UTF-8 UTF-8' /etc/locale.gen; then
    sudo sed -i 's/#zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen
fi
echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" | sudo tee /etc/locale.conf

# ⌨️ Install Fcitx5 with Chewing (注音)
echo "⌨️ Installing Fcitx5 and Chewing..."
for pkg in fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    else
        echo "$pkg already installed. Skipping..."
    fi
done

# 🔠 Install fonts
echo "🔤 Installing fonts..."
for fontpkg in noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation; do
    if ! pacman -Qi "$fontpkg" &>/dev/null; then
        echo "Installing $fontpkg..."
        sudo pacman -S --noconfirm "$fontpkg"
    else
        echo "$fontpkg already installed. Skipping..."
    fi
done

# ⚙️ Add fcitx5 startup script
echo "⚙️ Creating Fcitx5 environment script..."
mkdir -p ~/.config/hypr
FCITX_SCRIPT=~/.config/hypr/fcitx.sh
if [[ ! -f "$FCITX_SCRIPT" ]]; then
    cat <<'EOF' > "$FCITX_SCRIPT"
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
    chmod +x "$FCITX_SCRIPT"
else
    echo "Fcitx5 script already exists. Skipping..."
fi

# 🧩 Add to Hyprland config
echo "🧩 Updating Hyprland config to run fcitx..."
HYP_CONFIG=~/.config/hypr/hyprland.conf
if [[ -f "$HYP_CONFIG" ]] && ! grep -q 'exec-once = ~/.config/hypr/fcitx.sh' "$HYP_CONFIG"; then
    echo 'exec-once = ~/.config/hypr/fcitx.sh' >> "$HYP_CONFIG"
    echo "Appended exec-once to hyprland.conf"
else
    echo "Hyprland config already has fcitx script or does not exist. Skipping..."
fi

echo "✅ Hyprland and input method configured. Run 'fcitx5-configtool' to set input method."
