#!/bin/bash
set -e

# 🔧 Step 1: System Update and Base Tools
echo "🔧 Updating system and installing base packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git vim

# 📦 Step 2: Install yay (AUR helper)
echo "📦 Installing yay AUR helper..."
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~
rm -rf yay

# 🌏 Step 3: Set Traditional Chinese Locale
echo "🌏 Setting Traditional Chinese locale..."
# Enable zh_TW.UTF-8 in locale.gen
sudo sed -i 's/^#\(zh_TW.UTF-8 UTF-8\)/\1/' /etc/locale.gen
# Generate the locale
sudo locale-gen
# Set LANG and LC_CTYPE in locale.conf
echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf
echo 'LC_CTYPE=zh_TW.UTF-8' | sudo tee -a /etc/locale.conf

# 🖥 Step 4: Install Hyprland and Related Wayland Packages
echo "🖥 Installing Hyprland and related desktop tools..."
sudo pacman -S --noconfirm \
  hyprland xdg-desktop-portal-hyprland \
  kitty waybar wofi rofi \
  thunar thunar-archive-plugin file-roller \
  firefox neofetch grim slurp wl-clipboard \
  swaylock swayidle pamixer pavucontrol \
  pipewire pipewire-pulse wireplumber

# ⌨️ Step 5: Install Fcitx5 and Chewing Input Method
echo "⌨️ Installing fcitx5 and Chewing input method..."
sudo pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing

# 📝 Step 6: Create .xprofile with Fcitx5 Environment Variables
echo "📝 Writing ~/.xprofile with fcitx5 environment variables..."
cat <<EOF > ~/.xprofile
#!/bin/bash
# Fcitx5 input method environment settings
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS="@im=fcitx5"
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
export INPUT_METHOD=fcitx5
export MOZ_ENABLE_WAYLAND=1

# Start fcitx5 daemon if not running
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chmod +x ~/.xprofile

# 💡 Step 7: Configure Hyprland to Autostart Fcitx5
echo "💡 Configuring Hyprland to auto-launch fcitx5..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/fcitx.sh
#!/bin/bash
pgrep -x fcitx5 >/dev/null || fcitx5 -d &
EOF

chmod +x ~/.config/hypr/fcitx.sh

# Add to hyprland.conf if not already there
CONF=~/.config/hypr/hyprland.conf
if [ -f "$CONF" ]; then
  grep -q 'exec-once = ~/.config/hypr/fcitx.sh' "$CONF" || echo 'exec-once = ~/.config/hypr/fcitx.sh' >> "$CONF"
fi

# 🖋 Step 8: Install Fonts (CJK and UI)
echo "🖋 Installing fonts for CJK and UI..."
sudo pacman -S --noconfirm noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

# 🧠 Step 9: Install Neovim and Set Up LazyVim
echo "🧠 Installing Neovim and setting up LazyVim..."

# Install Neovim and related CLI tools
sudo pacman -S --noconfirm neovim unzip curl ripgrep fd python-pip

# Upgrade pip and install Python support for Neovim
pip install --upgrade pip
pip install --user pynvim

# Remove existing config if any (optional)
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim

# Clone LazyVim starter template
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove Git history to make it your own config
rm -rf ~/.config/nvim/.git

echo "✅ LazyVim installed. Run 'nvim' to bootstrap plugins."

# ✅ Final message
echo "✅ All done! Reboot to enter your Hyprland environment."
