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
echo "1) NVIDIA"
echo "2) AMD"
echo "3) Intel"
read -rp "Enter choice (1/2/3): " gpu_choice

case "$gpu_choice" in
    1)
        echo "Installing NVIDIA drivers (DKMS)..."
        sudo pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings
        ;;
    2)
        echo "Installing AMD drivers..."
        sudo pacman -S --noconfirm xf86-video-amdgpu mesa
        ;;
    3)
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
echo "3) Hyprland"
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
    3)
        echo "Installing Hyprland..."
        sudo pacman -S --noconfirm hyprland xorg-xwayland wayland wlroots alacritty kitty swaybg mako swayidle mesa mesa-vdpau pipewire pipewire-pulse
        echo "Running remote Hyprland dotfiles setup script..."
        bash <(curl -s https://ii.clsty.link/get)
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

# -----------------------------
# Done
# -----------------------------
echo "== SkywareOS full setup complete =="
echo "→ GPU drivers installed"
echo "→ Desktop environment / Hyprland configured"
echo "→ fastfetch branded with ASCII logo and OS name"
echo "→ /etc/os-release patched"
echo "→ btop themed"
echo "→ Starship zsh prompt enabled"
echo "→ Alacritty + Kitty dark-gray themed"
echo "→ Flatpak apps installed"
echo "Log out or reboot required"

