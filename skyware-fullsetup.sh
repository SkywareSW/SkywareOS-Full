#!/bin/bash
set -e

echo "== SkywareOS full setup starting =="

# -----------------------------
# Pacman packages (Kitty included)
# -----------------------------
sudo pacman -Syu --noconfirm \
    flatpak cmatrix fastfetch btop zsh alacritty kitty curl git base-devel

# -----------------------------
# GPU Driver Selection
# -----------------------------
echo "Select your GPU driver:"
echo "1) NVIDIA (Modern)"
echo "2) NVIDIA"
echo "3) AMD"
echo "4) Intel"
read -rp "Enter choice (1/2/3/4): " gpu_choice

case "$gpu_choice" in
    1)
        echo "Installing Modern NVIDIA drivers..."
        sudo pacman -S --noconfirm nvidia-open nvidia-utils nvidia-settings
        ;;
    
    2)
        echo "Installing NVIDIA drivers (DKMS)..."
        sudo pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings
        ;;
    3)
        echo "Installing AMD drivers..."
        sudo pacman -S --noconfirm xf86-video-amdgpu mesa
        ;;
    4)
        echo "Installing Intel drivers..."
        sudo pacman -S --noconfirm xf86-video-intel mesa
        ;;
    *)
        echo "Invalid choice, skipping GPU drivers."
        ;;
esac

# -----------------------------
# Desktop Environment / Compositor Selection
# -----------------------------
echo "Select your Desktop Environment / Compositor:"
echo "1) KDE Plasma"
echo "2) GNOME"
read -rp "Enter choice (1/2/3): " de_choice

case "$de_choice" in
    1)
        echo "Installing KDE Plasma..."
        sudo pacman -S --noconfirm plasma kde-applications sddm
        sudo systemctl enable sddm
        ;;
    2)
        echo "Installing GNOME..."
        sudo pacman -S --noconfirm gnome gnome-extra gdm
        sudo systemctl enable gdm
        ;;
    *)
        echo "Invalid choice, skipping DE installation."
        ;;
esac

# -----------------------------
# Flatpak apps
# -----------------------------
if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

flatpak install -y flathub \
    com.discordapp.Discord \
    com.spotify.Client \
    com.valvesoftware.Steam

# -----------------------------
# Fastfetch setup (ASCII logo)
# -----------------------------
FASTFETCH_DIR="$HOME/.config/fastfetch"
mkdir -p "$FASTFETCH_DIR/logos"

cat > "$FASTFETCH_DIR/logos/skyware.txt" << 'EOF'
      @@@@@@@-         +@@@@@@.     
    %@@@@@@@@@@=      @@@@@@@@@@   
   @@@@     @@@@@      -     #@@@  
  :@@*        @@@@             @@@ 
  @@@          @@@@            @@@ 
  @@@           @@@@           %@@ 
  @@@            @@@@          @@@ 
  :@@@            @@@@:        @@@ 
   @@@@     =      @@@@@     %@@@  
    @@@@@@@@@@       @@@@@@@@@@@   
      @@@@@@+          %@@@@@@     
EOF

cat > "$FASTFETCH_DIR/config.jsonc" << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/fastfetch/logos/skyware.txt",
    "padding": { "top": 0, "left": 2 }
  },
  "modules": [
    "title",
    "separator",
    { "type": "os", "format": "SkywareOS", "use_pretty_name": false },
    "kernel",
    "uptime",
    "packages",
    "shell",
    "cpu",
    "gpu",
    "memory"
  ]
}
EOF

# -----------------------------
# Patch /etc/os-release
# -----------------------------
if [ -w /etc/os-release ] || sudo -n true 2>/dev/null; then
    echo "== Patching /etc/os-release for SkywareOS =="
    sudo cp /etc/os-release /etc/os-release.backup
    sudo sed -i 's/^NAME=.*/NAME="SkywareOS"/' /etc/os-release
    sudo sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="SkywareOS"/' /etc/os-release
else
    echo "⚠️ Cannot write to /etc/os-release, skipping system-wide branding"
fi

# -----------------------------
# btop theme + config
# -----------------------------
BTOP_DIR="$HOME/.config/btop"
mkdir -p "$BTOP_DIR/themes"

cat > "$BTOP_DIR/themes/skyware-red.theme" << 'EOF'
theme[main_bg]="#0a0000"
theme[main_fg]="#f2dada"
theme[title]="#ff4d4d"
theme[hi_fg]="#ff6666"
theme[selected_bg]="#2a0505"
theme[inactive_fg]="#8a5a5a"

theme[cpu_box]="#ff4d4d"
theme[cpu_core]="#ff6666"
theme[cpu_misc]="#ff9999"

theme[mem_box]="#ff6666"
theme[mem_used]="#ff4d4d"
theme[mem_free]="#ff9999"
theme[mem_cached]="#ffb3b3"

theme[net_box]="#ff6666"
theme[net_download]="#ff9999"
theme[net_upload]="#ff4d4d"

theme[temp_start]="#ff9999"
theme[temp_mid]="#ff6666"
theme[temp_end]="#ff3333"
EOF

cat > "$BTOP_DIR/btop.conf" << 'EOF'
color_theme = "skyware-red"
rounded_corners = True
vim_keys = True
graph_symbol = "block"
update_ms = 2000
EOF

# -----------------------------
# zsh + Starship
# -----------------------------
chsh -s /bin/zsh "$USER" || true

if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh
fi

# Delete old configs to avoid warnings
rm -f ~/.config/starship.toml
rm -rf ~/.config/starship.d

mkdir -p ~/.config
cat > "$HOME/.zshrc" << 'EOF'
# Load Starship prompt
eval "$(starship init zsh)"
alias ll='ls -lah'
EOF

# Minimal Starship config (no warnings)
cat > "$HOME/.config/starship.toml" << 'EOF'
[character]
success_symbol = "➜"
error_symbol   = "✗"
vicmd_symbol   = "❮"

[directory]
truncation_length = 3
style = "gray"

[git_branch]
symbol = " "
style = "bright-gray"

[git_status]
style = "gray"
conflicted = "✖"
ahead = "↑"
behind = "↓"
staged = "●"
deleted = "✖"
renamed = "➜"
modified = "!"
untracked = "?"
EOF

# -----------------------------
# Alacritty dark-gray theme
# -----------------------------
ALACRITTY_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_DIR"

cat > "$ALACRITTY_DIR/alacritty.yml" << 'EOF'
colors:
  primary:
    background: '#1E1E1E'
    foreground: '#D4D4D4'
  normal:
    black:   '#1E1E1E'
    red:     '#FF5F5F'
    green:   '#5FFF5F'
    yellow:  '#FFFFAF'
    blue:    '#5F87FF'
    magenta: '#AF5FFF'
    cyan:    '#5FFFFF'
    white:   '#D4D4D4'
font:
  size: 11
EOF

# -----------------------------
# Kitty dark-gray theme
# -----------------------------
KITTY_DIR="$HOME/.config/kitty"
mkdir -p "$KITTY_DIR"

cat > "$KITTY_DIR/kitty.conf" << 'EOF'
background #1E1E1E
foreground #D4D4D4
selection_background #333333
selection_foreground #FFFFFF

color0  #1E1E1E
color1  #FF5F5F
color2  #5FFF5F
color3  #FFFFAF
color4  #5F87FF
color5  #AF5FFF
color6  #5FFFFF
color7  #D4D4D4

font_size 11
EOF

echo "== Finalizing Installation =="

# -----------------------------
# OS release branding (KDE reads this)
# -----------------------------
sudo tee /etc/os-release > /dev/null << 'EOF'
NAME="SkywareOS"
PRETTY_NAME="SkywareOS"
ID=skywareos
ID_LIKE=arch
VERSION="Beta"
VERSION_ID=rolling
HOME_URL="https://github.com/SkywareSW"
LOGO=skywareos
EOF

sudo tee /usr/lib/os-release > /dev/null << 'EOF'
NAME="SkywareOS"
PRETTY_NAME="SkywareOS"
ID=skywareos
ID_LIKE=arch
VERSION="Beta"
VERSION_ID=rolling
HOME_URL="https://skywareos.dev"
SUPPORT_URL="https://skywareos.dev/support"
BUG_REPORT_URL="https://skywareos.dev/bugs"
LOGO=skywareos
EOF

# -----------------------------
# Install distro logo (for KDE)
# -----------------------------
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps
sudo cp assets/skywareos.svg \
  /usr/share/icons/hicolor/scalable/apps/skywareos.svg

sudo gtk-update-icon-cache /usr/share/icons/hicolor

# -----------------------------
# SDDM branding (login screen)
# -----------------------------
sudo pacman -S --noconfirm sddm breeze sddm-kcm
sudo systemctl enable sddm

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-skywareos.conf > /dev/null << 'EOF'
[Theme]
Current=breeze
EOF

sudo mkdir -p /usr/share/sddm/themes/breeze/assets
sudo cp assets/skywareos.svg \
  /usr/share/sddm/themes/breeze/assets/logo.svg

# SDDM background
if [[ -f assets/skywareos-wallpaper.png ]]; then
  sudo cp assets/skywareos-wallpaper.png \
    /usr/share/sddm/themes/breeze/background.png
fi

# -----------------------------
# Plasma Splash Screen (Look & Feel)
# -----------------------------
sudo mkdir -p /usr/share/plasma/look-and-feel/org.skywareos.desktop/contents/splash

sudo tee /usr/share/plasma/look-and-feel/org.skywareos.desktop/metadata.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=SkywareOS
Comment=SkywareOS Plasma Look and Feel
Type=Service
X-KDE-ServiceTypes=Plasma/LookAndFeel
X-KDE-PluginInfo-Name=org.skywareos.desktop
X-KDE-PluginInfo-Author=SkywareOS
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL
EOF

sudo tee /usr/share/plasma/look-and-feel/org.skywareos.desktop/contents/splash/Splash.qml > /dev/null << 'EOF'
import QtQuick 2.15

Rectangle {
    color: "#1e1e1e"

    Image {
        anchors.centerIn: parent
        source: "logo.svg"
        width: 256
        height: 256
        fillMode: Image.PreserveAspectFit
    }
}
EOF

sudo cp assets/skywareos.svg \
  /usr/share/plasma/look-and-feel/org.skywareos.desktop/contents/splash/logo.svg

# Set Plasma splash automatically
kwriteconfig6 --file kscreenlockerrc --group Greeter --key Theme org.skywareos.desktop
kwriteconfig6 --file plasmarc --group Theme --key name org.skywareos.desktop

echo "→ SkywareOS Finalization Complete"

echo "== Creating SkywareOS distro-grade package manager (ware) =="

sudo tee /usr/local/bin/ware > /dev/null << 'EOF'
#!/bin/bash

LOGFILE="/var/log/ware.log"
JSON_MODE=false

GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOGFILE" >/dev/null
}

header() {
    [ "$JSON_MODE" = true ] && return
    echo -e "${BLUE}SkywareOS Package Manager (ware)${RESET}"
    echo ""
}

spinner() {
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}[%c] Working...${RESET}" "${spin:$i:1}"
        sleep .1
    done
    printf "\r"
}

have_paru() {
    command -v paru >/dev/null 2>&1
}

ensure_paru() {
    if ! have_paru; then
        echo -e "${YELLOW}→ Installing paru (AUR helper)...${RESET}"
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru || exit 1
        makepkg -si --noconfirm
        cd /
        rm -rf /tmp/paru
        log "paru installed"
    fi
}

install_pkg() {
    for pkg in "$@"; do
        log "Install requested: $pkg"

        if pacman -Si "$pkg" &>/dev/null; then
            sudo pacman -S --noconfirm "$pkg" &
            spinner
            wait
            log "Installed via pacman: $pkg"

        elif flatpak search "$pkg" | grep -qi "$pkg"; then
            flatpak install -y flathub "$pkg" &
            spinner
            wait
            log "Installed via flatpak: $pkg"

        else
            ensure_paru
            if paru -Si "$pkg" &>/dev/null; then
                paru -S --noconfirm "$pkg" &
                spinner
                wait
                log "Installed via AUR: $pkg"
            else
                echo -e "${RED}✖ Package not found: $pkg${RESET}"
                log "FAILED install: $pkg"
            fi
        fi
    done
}

remove_pkg() {
    for pkg in "$@"; do
        if pacman -Q "$pkg" &>/dev/null; then
            sudo pacman -Rns --noconfirm "$pkg"
            log "Removed: $pkg"
        elif have_paru && paru -Q "$pkg" &>/dev/null; then
            paru -Rns --noconfirm "$pkg"
            log "Removed AUR: $pkg"
        elif flatpak list | grep -qi "$pkg"; then
            flatpak uninstall -y "$pkg"
            log "Removed flatpak: $pkg"
        else
            echo -e "${RED}✖ $pkg not installed${RESET}"
        fi
    done
}

doctor() {
    header
    sudo pacman -Dk
    flatpak repair --dry-run
    echo -e "${GREEN}Diagnostics complete.${RESET}"
}

clean_cache() {
    sudo pacman -Sc --noconfirm
    flatpak uninstall --unused -y
    log "Cache cleaned"
}

autoremove() {
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null
    log "Autoremove executed"
}

sync_mirrors() {
    sudo pacman -S --noconfirm reflector
    sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    log "Mirrors synced"
}

interactive_install() {
    read -rp "Enter package name: " pkg
    install_pkg "$pkg"
}

if [[ "$1" == "--json" ]]; then
    JSON_MODE=true
    shift
fi

case "$1" in
    install) shift; header; install_pkg "$@" ;;
    remove) shift; header; remove_pkg "$@" ;;
    update) header; sudo pacman -Syu; flatpak update -y; log "System updated" ;;
    search) shift; header; pacman -Ss "$@"; flatpak search "$@" ;;
    info) shift; header; pacman -Si "$1" 2>/dev/null || (have_paru && paru -Si "$1") || flatpak info "$1" ;;
    list) header; pacman -Q; flatpak list ;;
    doctor) doctor ;;
    clean) clean_cache ;;
    setup)
        shift
        case "$1" in
            hyprland)
                header
                echo -e "${YELLOW}→ Installing Hyprland environment...${RESET}"
                log "Hyprland setup started"

                sudo pacman -S --noconfirm \
                    hyprland \
                    xdg-desktop-portal-hyprland \
                    waybar \
                    wofi \
                    kitty \
                    grim \
                    slurp \
                    wl-clipboard \
                    polkit-kde-agent \
                    pipewire wireplumber \
                    network-manager-applet \
                    thunar

                echo -e "${GREEN}✔ Base Hyprland packages installed${RESET}"

                echo -e "${YELLOW}→ Running Skyware Hyprland dotfiles setup(jakoolit)...${RESET}"
                sh <(curl -L https://raw.githubusercontent.com/JaKooLit/Hyprland-Dots/main/Distro-Hyprland.sh)

                log "Hyprland setup completed"
                echo -e "${GREEN}✔ Hyprland setup complete${RESET}"
                ;;
            *)
                echo -e "${RED}Unknown setup target${RESET}"
                ;;
        esac
        ;;
    autoremove) autoremove ;;
    sync) sync_mirrors ;;
    interactive) interactive_install ;;
    *) 
        header
        echo "Usage:"
        echo "  ware install <pkg>"
        echo "  ware remove <pkg>"
        echo "  ware update"
        echo "  ware search <pkg>"
        echo "  ware info <pkg>"
        echo "  ware list"
        echo "  ware doctor"
        echo "  ware clean"
        echo "  ware autoremove"
        echo "  ware sync"
        echo "  ware interactive"
        echo "  ware --json <command>"
        echo "  ware setup hyprland"
        echo "  ware setup hyprland-end4(may require manual intervention/is buggy)"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/ware


# -----------------------------
# Done
# -----------------------------
echo "== SkywareOS full setup complete =="
echo "Log out or reboot required"








