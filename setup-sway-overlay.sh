#!/bin/sh
# ---------------------------------------------------------------------------
# setup-sway-overlay.sh
#
# Generates a live-build config/ overlay for a Sway-based Debian spin:
#   sway + swaybg + swayidle + swaylock, waybar, wofi, foot
#   pipewire audio, NetworkManager, mako notifications, xdg portals, polkit
#   greetd (agreety text greeter) launching a Wayland session
#
# USAGE
#   1. On a Debian machine:  sudo apt install live-build
#   2. mkdir my-distro && cd my-distro
#   3. lb config \
#        --distribution bookworm \
#        --archive-areas "main contrib non-free non-free-firmware" \
#        --debian-installer live
#   4. sh /path/to/setup-sway-overlay.sh      # run from INSIDE my-distro
#   5. sudo lb build
#
# Re-runnable: it overwrites the files it manages and leaves the rest alone.
# ---------------------------------------------------------------------------
set -eu

if [ ! -d config ]; then
    echo "error: no ./config directory found." >&2
    echo "Run this from your live-build project root (after 'lb config')." >&2
    exit 1
fi

SKEL="config/includes.chroot/etc/skel/.config"
BIN="config/includes.chroot/usr/local/bin"

mkdir -p \
    config/package-lists \
    config/hooks/normal \
    config/includes.chroot/etc/greetd \
    "$BIN" \
    "$SKEL/sway" "$SKEL/waybar" "$SKEL/foot" "$SKEL/wofi" "$SKEL/mako"

# ---------------------------------------------------------------------------
# 1. Package selection
# ---------------------------------------------------------------------------
cat > config/package-lists/desktop.list.chroot <<'EOF'
# --- Wayland compositor + core session ---
sway
swaybg
swayidle
swaylock
xwayland

# --- Bar / launcher / terminal ---
waybar
wofi
foot

# --- Wayland utilities ---
wl-clipboard
grim
slurp
mako-notifier
brightnessctl
playerctl

# --- Portals (screen share, native file pickers) ---
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-desktop-portal-gtk
xdg-utils

# --- Audio (PipeWire) ---
pipewire
pipewire-pulse
wireplumber
pavucontrol

# --- Network ---
network-manager
network-manager-gnome

# --- Session bits: login greeter + polkit agent ---
greetd
mate-polkit

# --- Fonts (Font Awesome supplies most waybar glyphs) ---
fonts-dejavu
fonts-font-awesome
fonts-noto-color-emoji
EOF

# ---------------------------------------------------------------------------
# 2. Session launcher — sets Wayland env vars, then execs sway.
#    greetd points at this so the env is right regardless of login path.
# ---------------------------------------------------------------------------
cat > "$BIN/start-sway" <<'EOF'
#!/bin/sh
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export _JAVA_AWT_WM_NONREPARENTING=1
exec sway "$@"
EOF
chmod 755 "$BIN/start-sway"

# ---------------------------------------------------------------------------
# 3. greetd — agreety (ships with greetd) authenticates, then runs start-sway
# ---------------------------------------------------------------------------
cat > config/includes.chroot/etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "agreety --cmd start-sway"
user = "greeter"
EOF

# ---------------------------------------------------------------------------
# 4. Sway config
# ---------------------------------------------------------------------------
cat > "$SKEL/sway/config" <<'EOF'
### Variables
set $mod Mod4
set $term foot
set $menu wofi --show drun
set $left h
set $down j
set $up k
set $right l

### Appearance
font pango:DejaVu Sans 10
default_border pixel 2
gaps inner 6

### Wallpaper (solid colour fallback; swap for an image if you like:
###   output * bg /usr/share/backgrounds/mydistro.png fill)
output * bg #1e1e2e solid_color

### Idle: lock after 5 min, screen off after 10, lock before sleep
exec swayidle -w \
    timeout 300 'swaylock -f -c 1e1e2e' \
    timeout 600 'swaymsg "output * power off"' \
    resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f -c 1e1e2e'

### Touchpad defaults (ignored on machines without one)
input "type:touchpad" {
    tap enabled
    natural_scroll enabled
}

### Autostart
exec waybar
exec mako
exec nm-applet --indicator
# Polkit agent. If auth dialogs never appear, confirm the path with
#   dpkg -L mate-polkit | grep authentication-agent
exec /usr/lib/mate-polkit/polkit-mate-authentication-agent-1

### Launch / window management
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning \
    -m 'Exit sway?' -B 'Yes, exit' 'swaymsg exit'

### Focus
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

### Move
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

### Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

### Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle
bindsym $mod+a focus parent

### Resize mode
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

### Screenshots (grim + slurp)
bindsym Print exec grim ~/Pictures/$(date +'%Y-%m-%d-%H%M%S').png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Pictures/$(date +'%Y-%m-%d-%H%M%S').png

### Media / brightness keys
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

### Drag/resize floating windows with the mouse
floating_modifier $mod normal
EOF

# ---------------------------------------------------------------------------
# 5. Waybar
# ---------------------------------------------------------------------------
cat > "$SKEL/waybar/config.jsonc" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 6,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],

    "sway/workspaces": { "disable-scroll": true, "all-outputs": true },

    "clock": {
        "format": "{:%a %d %b  %H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "cpu":    { "format": " {usage}%" },
    "memory": { "format": " {}%" },

    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""],
        "states": { "warning": 30, "critical": 15 }
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ipaddr}",
        "format-disconnected": " off"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " muted",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol"
    },

    "tray": { "spacing": 8 }
}
EOF

cat > "$SKEL/waybar/style.css" <<'EOF'
* {
    font-family: "DejaVu Sans", "Font Awesome 5 Free";
    font-size: 13px;
    border: none;
    border-radius: 0;
}
window#waybar {
    background: #1e1e2e;
    color: #cdd6f4;
}
#workspaces button {
    padding: 0 8px;
    color: #cdd6f4;
    background: transparent;
}
#workspaces button.focused {
    background: #313244;
    border-bottom: 2px solid #89b4fa;
}
#clock, #cpu, #memory, #battery, #network, #pulseaudio, #tray {
    padding: 0 10px;
}
#battery.warning  { color: #f9e2af; }
#battery.critical { color: #f38ba8; }
EOF

# ---------------------------------------------------------------------------
# 6. Foot
# ---------------------------------------------------------------------------
cat > "$SKEL/foot/foot.ini" <<'EOF'
font=DejaVu Sans Mono:size=11
pad=8x8

[colors]
background=1e1e2e
foreground=cdd6f4
EOF

# ---------------------------------------------------------------------------
# 7. Wofi
# ---------------------------------------------------------------------------
cat > "$SKEL/wofi/config" <<'EOF'
show=drun
width=600
lines=8
prompt=Run
insensitive=true
allow_images=true
EOF

cat > "$SKEL/wofi/style.css" <<'EOF'
window { background-color: #1e1e2e; color: #cdd6f4; border-radius: 8px; }
#input { margin: 6px; padding: 6px; background: #313244; color: #cdd6f4; border: none; }
#entry:selected { background: #89b4fa; color: #1e1e2e; }
EOF

# ---------------------------------------------------------------------------
# 8. Mako notifications
# ---------------------------------------------------------------------------
cat > "$SKEL/mako/config" <<'EOF'
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-radius=6
default-timeout=5000
EOF

# ---------------------------------------------------------------------------
# 9. Build-time hook: enable services, boot to graphical target
# ---------------------------------------------------------------------------
cat > config/hooks/normal/0100-services.hook.chroot <<'EOF'
#!/bin/sh
set -e
systemctl enable greetd
systemctl enable NetworkManager
systemctl set-default graphical.target
EOF
chmod 755 config/hooks/normal/0100-services.hook.chroot

echo "Overlay written. Next: sudo lb build"