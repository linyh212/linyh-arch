#!/bin/bash

# -------------------------------
# Arch Linux + Hyprland Setup Script
# Author: Compiled by ChatGPT
# -------------------------------

set -e  # Exit on any error

# Step 0: Ensure root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi

# Get the actual username (not root)
USERNAME=${SUDO_USER:-$(logname)}
USER_HOME="/home/$USERNAME"

# Step 1: Install essential packages
pacman -Sy --noconfirm git base-devel vim

# Step 2: Install yay (AUR helper)
if [ ! -d "$USER_HOME/yay" ]; then
  sudo -u "$USERNAME" git clone https://aur.archlinux.org/yay.git "$USER_HOME/yay"
  cd "$USER_HOME/yay"
  sudo -u "$USERNAME" makepkg -si --noconfirm
fi

# Step 3: Clone and run JaKooLit Hyprland script
if [ ! -d "$USER_HOME/Arch-Hyprland" ]; then
  sudo -u "$USERNAME" git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git "$USER_HOME/Arch-Hyprland"
  cd "$USER_HOME/Arch-Hyprland"
  chmod +x install.sh
  sudo -u "$USERNAME" ./install.sh
fi

# Step 4: Enable zh_TW.UTF-8 locale
sed -i 's/^#\(zh_TW\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" > /etc/locale.conf

# Step 5: Install Fcitx5 and Chewing input method
pacman -S --noconfirm fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing
pacman -S --noconfirm noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation

# Step 6: Create ~/.xprofile with Fcitx5 environment variables
XPROFILE="$USER_HOME/.xprofile"
cat <<'EOF' > "$XPROFILE"
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

chown "$USERNAME:$USERNAME" "$XPROFILE"
chmod +x "$XPROFILE"

# Step 7: Create Hyprland Fcitx5 startup script and hook it
FCITX_SCRIPT="$USER_HOME/.config/hypr/fcitx.sh"
mkdir -p "$(dirname "$FCITX_SCRIPT")"
cp "$XPROFILE" "$FCITX_SCRIPT"
chown "$USERNAME:$USERNAME" "$FCITX_SCRIPT"
chmod +x "$FCITX_SCRIPT"

HCONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HCONF" ] && ! grep -q "exec-once = ~/.config/hypr/fcitx.sh" "$HCONF"; then
  echo "exec-once = ~/.config/hypr/fcitx.sh" >> "$HCONF"
  chown "$USERNAME:$USERNAME" "$HCONF"
fi

echo -e "\n✅ All setup steps completed successfully!"
echo "➡️  Please reboot and log in to Hyprland to start using your configured system."
