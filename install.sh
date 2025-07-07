#!/bin/bash
set -euo pipefail

log() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        cp -v "$file" "$backup"
        log "Backed up $file to $backup"
    fi
}

install_if_not_exists() {
    local PKG="$1"
    if pacman -Qi "$PKG" &>/dev/null || yay -Qi "$PKG" &>/dev/null; then
        log "Package '$PKG' is already installed. Skipping."
    else
        log "Installing package '$PKG' ..."
        yay -S --noconfirm "$PKG"
    fi
}

install_multi_if_not_exists() {
    local PKGS_TO_INSTALL=()
    for PKG in "$@"; do
        if ! pacman -Qi "$PKG" &>/dev/null && ! yay -Qi "$PKG" &>/dev/null; then
            PKGS_TO_INSTALL+=("$PKG")
        else
            log "Package '$PKG' is already installed. Skipping."
        fi
    done

    if [ ${#PKGS_TO_INSTALL[@]} -gt 0 ]; then
        log "Installing packages: ${PKGS_TO_INSTALL[*]}"
        yay -S --noconfirm "${PKGS_TO_INSTALL[@]}"
    else
        log "All packages already installed."
    fi
}

main() {
    log "Starting system update..."
    sudo pacman -Syu --noconfirm

    install_if_not_exists base-devel

    log "Installing yay (AUR helper) if missing..."
    if ! command -v yay &> /dev/null; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd ~
    else
        log "yay already installed."
    fi

    log "Installing Hyprland and components..."
    install_multi_if_not_exists \
    hyprland hyprlock hypridle wlogout \
    swww hyprpaper swaybg \
    waybar playerctl brightnessctl pamixer jq wl-clipboard pavucontrol \
    grim slurp swappy mako \
    network-manager-applet xdg-desktop-portal-hyprland \
    noto-fonts-cjk noto-fonts ttf-dejavu ttf-liberation \
    ttf-jetbrains-mono-nerd ttf-fira-code-nerd ttf-hack-nerd \
    neovim kitty

    log "Installing Fcitx5 and Chewing ..."
    install_multi_if_not_exists fcitx5-im fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chewing

    log "Backing up and setting locale..."
    backup_file /etc/locale.conf
    echo -e "LANG=en_US.UTF-8\nLC_CTYPE=zh_TW.UTF-8" | sudo tee /etc/locale.conf

    log "Running setup-locale.sh script..."
    local setup_locale_path
    setup_locale_path="$(dirname "$0")/scripts/setup-locale.sh"
    if [[ -f "$setup_locale_path" ]]; then
        bash "$setup_locale_path"
    else
        error "setup-locale.sh not found at $setup_locale_path"
        exit 1
    fi

    log "Backing up and copying fcitx.sh..."
    mkdir -p ~/.config/hypr
    backup_file ~/.config/hypr/fcitx.sh
    local fcitx_sh_path="$(dirname "$0")/scripts/fcitx.sh"
    if [[ -f "$fcitx_sh_path" ]]; then
        cp "$fcitx_sh_path" ~/.config/hypr/fcitx.sh
        chmod +x ~/.config/hypr/fcitx.sh
    else
        error "fcitx.sh not found at $fcitx_sh_path"
        exit 1
    fi

    log "Writing ~/.xprofile with fcitx environment variables..."
    backup_file ~/.xprofile
    cat > ~/.xprofile <<'EOF'
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

    log "Backing up and copying config files..."
    backup_file ~/.config/hypr/hyprland.conf
    cp -r config/hypr/*.conf ~/.config/hypr/
    cp -r config/kitty ~/.config/
    cp -r config/waybar ~/.config/
    cp -r config/wlogout ~/.config/

    log "Enabling autostart commands in hyprland.conf..."
    CONFIG_PATH="$HOME/.config/hypr/hyprland.conf"
    for CMD in \
        "exec-once = ~/.config/hypr/fcitx.sh" \
        "exec-once = waybar" \
        "exec-once = hypridle" \
        "exec-once = swww-daemon"; do
        grep -qxF "$CMD" "$CONFIG_PATH" || echo "$CMD" >> "$CONFIG_PATH"
    done

    log "Setting up LazyVim..."
    mv ~/.config/nvim ~/.config/nvim.backup.$(date +%s) 2>/dev/null || true
    mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%s) 2>/dev/null || true
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git

    log "Installing and configuring Fastfetch..."
    install_if_not_exists fastfetch

    log "Installing zsh and oh-my-zsh..."
    install_multi_if_not_exists zsh git

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        log "oh-my-zsh already installed."
    fi

    if [[ "$SHELL" != *"zsh" ]]; then
        log "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
    fi

    log "Creating ~/.zshrc with fastfetch..."
    backup_file ~/.zshrc
    cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Show system info using fastfetch
if command -v fastfetch &>/dev/null; then
    fastfetch
fi
EOF

    log "Installing VSCode and Spotify..."
    install_multi_if_not_exists visual-studio-code-bin spotify

    log "✅ Setup complete! Please reboot and log in to Hyprland."
    echo "💡 You can run: fcitx5-configtool to add Chewing input method."
}

main "$@"
