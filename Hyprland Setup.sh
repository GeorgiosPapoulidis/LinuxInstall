#!/usr/bin/env bash
set -euo pipefail

source "Config.env"

mkdir -p ~/.config/{hypr,waybar,dunst,rofi,kitty,gtk-3.0,gtk-4.0,qt5ct,qt6ct,environment.d,systemd/user}
mkdir -p ~/.config/wallust/templates
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/{Wallpapers,Screenshots}
mkdir -p ~/Videos/"Desktop Backgrounds"
mkdir -p ~/.cache/wallpaper-videos

magick -size 1920x1080 gradient:'#1e1e2e-#11111b' ~/.cache/current_wallpaper.png 2>/dev/null || \
    cp /usr/share/hypr/wall0.png ~/.cache/current_wallpaper.png 2>/dev/null || true

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'

cat << 'EOF' > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
EOF

cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

cat << 'EOF' > ~/.config/qt5ct/qt5ct.conf
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=true
icon_theme=Papirus-Dark
standard_dialogs=default
style=Fusion
EOF

cat << 'EOF' > ~/.config/qt6ct/qt6ct.conf
[Appearance]
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
custom_palette=true
icon_theme=Papirus-Dark
standard_dialogs=default
style=Fusion
EOF

cat << 'EOF' > ~/.Xresources
Xft.dpi: 96
EOF

cat << 'EOF' > ~/.config/hypr/colors.conf
$active_border_1 = rgba(89b4faee)
$active_border_2 = rgba(cba6f7ee)
$inactive_border = rgba(45475aaa)
EOF

cat << 'EOF' > ~/.config/waybar/colors.css
@define-color bg_main rgba(30, 30, 46, 0.78);
@define-color bg_module rgba(49, 50, 68, 0.65);
@define-color fg_main #cdd6f4;
@define-color accent_primary #89b4fa;
@define-color accent_secondary #cba6f7;
@define-color accent_green #a6e3a1;
@define-color accent_yellow #f9e2af;
@define-color accent_pink #f5c2e7;
@define-color accent_red #f38ba8;
EOF

cat << 'EOF' > ~/.config/rofi/colors.rasi
* {
    bg: rgba(30, 30, 46, 0.88);
    bg-alt: rgba(49, 50, 68, 0.75);
    fg: #cdd6f4;
    accent: #89b4fa;
}
EOF

cat << 'EOF' > ~/.config/kitty/colors.conf
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E

color0 #45475A
color8 #585B70
color1 #F38BA8
color9 #F38BA8
color2 #A6E3A1
color10 #A6E3A1
color3 #F9E2AF
color11 #F9E2AF
color4 #89B4FA
color12 #89B4FA
color5 #F5C2E7
color13 #F5C2E7
color6 #94E2D5
color14 #94E2D5
color7 #BAC2DE
color15 #A6ADC8
EOF

cat << 'EOF' > ~/.config/wallust/templates/hypr.conf
$active_border_1 = rgba({{color4 | strip}}ee)
$active_border_2 = rgba({{color5 | strip}}ee)
$inactive_border = rgba({{color0 | strip}}aa)
EOF

cat << 'EOF' > ~/.config/wallust/templates/waybar.css
@define-color bg_main {{background}};
@define-color bg_module {{color0}};
@define-color fg_main {{foreground}};
@define-color accent_primary {{color4}};
@define-color accent_secondary {{color5}};
@define-color accent_green {{color2}};
@define-color accent_yellow {{color3}};
@define-color accent_pink {{color13}};
@define-color accent_red {{color1}};
EOF

cat << 'EOF' > ~/.config/wallust/templates/rofi.rasi
* {
    bg: {{background}};
    bg-alt: {{color0}};
    fg: {{foreground}};
    accent: {{color4}};
}
EOF

cat << 'EOF' > ~/.config/wallust/templates/kitty.conf
foreground              {{foreground}}
background              {{background}}
selection_foreground    {{background}}
selection_background    {{color4}}
cursor                  {{color4}}
cursor_text_color       {{background}}

color0 {{color0}}
color8 {{color8}}
color1 {{color1}}
color9 {{color9}}
color2 {{color2}}
color10 {{color10}}
color3 {{color3}}
color11 {{color11}}
color4 {{color4}}
color12 {{color12}}
color5 {{color5}}
color13 {{color13}}
color6 {{color6}}
color14 {{color14}}
color7 {{color7}}
color15 {{color15}}
EOF

cat << 'EOF' > ~/.config/wallust/wallust.toml
backend = "resized"
color_space = "lch"
palette = "dark16"
threshold = 15

[templates]
hypr = { template = "hypr.conf", target = "~/.config/hypr/colors.conf" }
waybar = { template = "waybar.css", target = "~/.config/waybar/colors.css" }
rofi = { template = "rofi.rasi", target = "~/.config/rofi/colors.rasi" }
kitty = { template = "kitty.conf", target = "~/.config/kitty/colors.conf" }
EOF

cat << 'EOF' > ~/.local/bin/wallpaper-rotator.sh
#!/usr/bin/env bash
set -uo pipefail

WALL_DIR="$HOME/Videos/Desktop Backgrounds"
CACHE_DIR="$HOME/.cache/wallpaper-videos"
FRAME_IMG="$HOME/.cache/current_wallpaper.png"
MPV_SOCK="/tmp/mpv-wallpaper.sock"
PENDING_FILE="/tmp/wallpaper_pending_action"
STATE_FILE="/tmp/current_wallpaper_video"
LOCK_FILE="/tmp/wallpaper_rotator.lock"

mkdir -p "$CACHE_DIR"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

MODE="${1:---rotate}"

if [[ "$MODE" == "--boot" ]]; then
    rm -f "$STATE_FILE" "$PENDING_FILE"
fi

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    if [[ "$MODE" != "--force" && "$MODE" != "--boot" ]]; then
        has_fs=$(hyprctl clients -j | jq '[.[] | select(.fullscreen != 0)] | length' 2>/dev/null || echo 0)
        if (( has_fs > 0 )); then
            if [[ "$MODE" == "--res-change" ]]; then
                [[ ! -f "$PENDING_FILE" ]] && echo "res-change" > "$PENDING_FILE"
            else
                echo "rotate" > "$PENDING_FILE"
            fi
            exit 0
        fi
    fi
fi

rm -f "$PENDING_FILE"

mapfile -d '' -t videos < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.mov" \) -print0 2>/dev/null)

if (( ${#videos[@]} == 0 )); then
    exit 0
fi

current_vid=""
[[ -f "$STATE_FILE" ]] && current_vid=$(cat "$STATE_FILE")

if [[ "$MODE" == "--res-change" && -n "$current_vid" && -f "$current_vid" ]]; then
    chosen_vid="$current_vid"
else
    rand_seed=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
    chosen_vid="${videos[rand_seed % ${#videos[@]}]}"
    if (( ${#videos[@]} > 1 )) && [[ -n "$current_vid" ]]; then
        for _ in {1..15}; do
            [[ "$chosen_vid" != "$current_vid" ]] && break
            rand_seed=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
            chosen_vid="${videos[rand_seed % ${#videos[@]}]}"
        done
    fi
fi

echo "$chosen_vid" > "$STATE_FILE"

max_h=1080
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    detected_h=$(hyprctl monitors -j | jq '[.[].height] | max' 2>/dev/null || echo 1080)
    [[ "$detected_h" =~ ^[0-9]+$ ]] && (( detected_h > 0 )) && max_h=$detected_h
fi

src_h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$chosen_vid" 2>/dev/null | head -n 1 || echo 2160)
[[ "$src_h" =~ ^[0-9]+$ ]] || src_h=2160

play_vid="$chosen_vid"
scale_filter=""

if (( src_h > max_h )); then
    res_dir="${CACHE_DIR}/${max_h}p"
    mkdir -p "$res_dir"
    base_name=$(basename "$chosen_vid")
    cached_vid="${res_dir}/${base_name%.*}.mp4"

    if [[ -f "$cached_vid" ]]; then
        play_vid="$cached_vid"
    else
        (
            nice -n 19 ffmpeg -y -loglevel error -hwaccel auto -i "$chosen_vid" \
                -vf "scale=-2:${max_h}" -c:v h264_nvenc -cq 23 -preset p4 -an "${cached_vid}.tmp" 2>/dev/null || \
            nice -n 19 ffmpeg -y -loglevel error -i "$chosen_vid" \
                -vf "scale=-2:${max_h}" -c:v libx264 -crf 22 -preset veryfast -an "${cached_vid}.tmp" 2>/dev/null
            [[ -f "${cached_vid}.tmp" ]] && mv "${cached_vid}.tmp" "$cached_vid"
        ) &
        scale_filter="vf=scale=-2:${max_h}"
    fi
fi

ffmpeg -y -loglevel error -i "$chosen_vid" -frames:v 1 -vf "scale=1920:-2" "$FRAME_IMG" 2>/dev/null || true

if [[ -S "$MPV_SOCK" ]] && pgrep -x mpvpaper >/dev/null 2>&1; then
    for b in -15 -30 -45 -60 -75 -90 -100; do
        printf '{ "command": ["set_property", "brightness", %d] }\n' "$b" | socat - "$MPV_SOCK" >/dev/null 2>&1 || true
        sleep 0.05
    done
fi

if [[ "$MODE" != "--res-change" ]] && [[ -f "$FRAME_IMG" ]] && command -v wallust >/dev/null 2>&1; then
    wallust run -q "$FRAME_IMG" || true
    hyprctl reload >/dev/null 2>&1 || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true
fi

if [[ -S "$MPV_SOCK" ]] && pgrep -x mpvpaper >/dev/null 2>&1; then
    printf '{ "command": ["loadfile", "%s", "replace"] }\n' "$play_vid" | socat - "$MPV_SOCK" >/dev/null 2>&1 || true
    if [[ -n "$scale_filter" ]]; then
        printf '{ "command": ["set_property", "vf", "scale=-2:%d"] }\n' "$max_h" | socat - "$MPV_SOCK" >/dev/null 2>&1 || true
    else
        printf '{ "command": ["set_property", "vf", ""] }\n' | socat - "$MPV_SOCK" >/dev/null 2>&1 || true
    fi
    sleep 0.25
    for b in -85 -70 -55 -40 -25 -10 0; do
        printf '{ "command": ["set_property", "brightness", %d] }\n' "$b" | socat - "$MPV_SOCK" >/dev/null 2>&1 || true
        sleep 0.05
    done
else
    rm -f "$MPV_SOCK"
    mpv_opts="no-audio loop hwdec=auto-safe vo=gpu vd-lavc-dr=yes swapchain-depth=2 input-ipc-server=$MPV_SOCK"
    [[ -n "$scale_filter" ]] && mpv_opts="$mpv_opts $scale_filter"
    mpvpaper -f -o "$mpv_opts" '*' "$play_vid" >/dev/null 2>&1 &
fi
EOF
chmod +x ~/.local/bin/wallpaper-rotator.sh

cat << 'EOF' > ~/.local/bin/wallpaper-watcher.sh
#!/usr/bin/env bash
set -uo pipefail

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
PENDING_FILE="/tmp/wallpaper_pending_action"
MON_SIG_FILE="/tmp/hypr_monitor_signature"

while [[ ! -S "$SOCK" ]]; do
    sleep 1
done

get_mon_sig() {
    hyprctl monitors -j 2>/dev/null | jq -c '[.[] | {name, width, height, scale, transform}]' 2>/dev/null || echo ""
}

get_mon_sig > "$MON_SIG_FILE"

flush_pending_if_free() {
    if [[ -f "$PENDING_FILE" ]]; then
        has_fs=$(hyprctl clients -j | jq '[.[] | select(.fullscreen != 0)] | length' 2>/dev/null || echo 0)
        if (( has_fs == 0 )); then
            action=$(cat "$PENDING_FILE" 2>/dev/null || echo "rotate")
            rm -f "$PENDING_FILE"
            if [[ "$action" == "res-change" ]]; then
                ~/.local/bin/wallpaper-rotator.sh --res-change &
            else
                ~/.local/bin/wallpaper-rotator.sh --force &
            fi
        fi
    fi
}

check_monitors() {
    new_sig=$(get_mon_sig)
    old_sig=$(cat "$MON_SIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$new_sig" && "$new_sig" != "$old_sig" ]]; then
        echo "$new_sig" > "$MON_SIG_FILE"
        ~/.local/bin/wallpaper-rotator.sh --res-change &
    fi
}

(
    while sleep 5; do
        check_monitors
        flush_pending_if_free
    done
) &

socat -U - UNIX-CONNECT:"$SOCK" | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>0*|closewindow*|activewindow*|workspace*)
            flush_pending_if_free
            ;;
        monitoradded*|monitorremoved*|configreloaded*)
            sleep 0.5
            check_monitors
            ;;
    esac
done
EOF
chmod +x ~/.local/bin/wallpaper-watcher.sh

cat << 'EOF' > ~/.config/systemd/user/wallpaper-rotate.service
[Unit]
Description=Rotate Video Wallpaper and Update System Theme Colors
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/wallpaper-rotator.sh --rotate
EOF

cat << 'EOF' > ~/.config/systemd/user/wallpaper-rotate.timer
[Unit]
Description=Rotate Video Wallpaper Every 6 Hours

[Timer]
OnUnitActiveSec=6h

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable wallpaper-rotate.timer

cat << 'EOF' > ~/.local/bin/check-nvme-space.sh
#!/usr/bin/env bash
set -euo pipefail

usage=$(df --output=pcent / | tail -n 1 | tr -dc '0-9')
if (( usage >= 90 )); then
    zenity --warning \
        --title="Storage Alert: NVMe Pool Critical" \
        --text="Btrfs pool usage on nvme0n1 is at ${usage}% (exceeds 90% threshold).\nOld snapshots or archived kernels should be pruned." \
        --width=420
fi
EOF
chmod +x ~/.local/bin/check-nvme-space.sh

cat << 'EOF' > ~/.local/bin/gamescope-hdr
#!/usr/bin/env bash
exec gamescope --hdr-enabled --hdr-sdr-content-nits 400 -f -- "$@"
EOF
chmod +x ~/.local/bin/gamescope-hdr

cat << 'EOF' > ~/.local/bin/powermenu.sh
#!/usr/bin/env bash
set -euo pipefail

lock=$(printf '\U000f033e  Lock')
suspend=$(printf '\U000f0904  Suspend')
logout=$(printf '\U000f0343  Logout')
reboot=$(printf '\U000f0709  Reboot')
shutdown=$(printf '\U000f0425  Shutdown')

chosen=$(printf "%s\n%s\n%s\n%s\n%s\n" "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi -dmenu -i -p "Power")

case "$chosen" in
    "$lock") hyprlock ;;
    "$suspend") systemctl suspend ;;
    "$logout") hyprctl dispatch exit ;;
    "$reboot") systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
EOF
chmod +x ~/.local/bin/powermenu.sh

cat << 'EOF' > ~/.local/bin/dunst-status.sh
#!/usr/bin/env bash
if dunstctl is-paused | grep -q "true"; then
    printf '\U000f009b\n'
else
    printf '\U000f009a\n'
fi
EOF
chmod +x ~/.local/bin/dunst-status.sh

cat << 'EOF' > ~/.config/hypr/hypridle.conf
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

cat << 'EOF' > ~/.config/hypr/hyprlock.conf
general {
    hide_cursor = true
    grace = 0
}

background {
    monitor =
    path = ~/.cache/current_wallpaper.png
    blur_passes = 3
    blur_size = 6
    color = rgba(30, 30, 46, 1.0)
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(205, 214, 244, 1.0)
    font_size = 64
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 100
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] echo "$(date +"%A, %d/%m/%Y")"
    color = rgba(137, 180, 250, 1.0)
    font_size = 18
    font_family = JetBrainsMono Nerd Font
    position = 0, 30
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 280, 55
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.2
    outer_color = rgba(137, 180, 250, 1.0)
    inner_color = rgba(30, 30, 46, 0.85)
    font_color = rgb(205, 214, 244)
    fade_on_empty = false
    placeholder_text = <i>Password...</i>
    position = 0, -50
    halign = center
    valign = center
}
EOF

cat << 'EOF' > ~/.config/hypr/hyprland.conf
monitor = ,preferred,auto,1

source = ~/.config/hypr/colors.conf

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GTK_THEME,adw-gtk3-dark
env = XCURSOR_SIZE,24

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/hyprpolkitagent/hyprpolkitagent
exec-once = xrdb -merge ~/.Xresources
exec-once = ~/.local/bin/wallpaper-rotator.sh --boot
exec-once = ~/.local/bin/wallpaper-watcher.sh
exec-once = systemctl --user start wallpaper-rotate.timer
exec-once = waybar
exec-once = dunst
exec-once = swayosd-server
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = udiskie --no-automount --smart-tray
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
exec-once = ~/.local/bin/check-nvme-space.sh

input {
    kb_layout = us,gr
    kb_options = grp:alt_shift_toggle
    numlock_by_default = true
    follow_mouse = 1
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = $active_border_1 $active_border_2 45deg
    col.inactive_border = $inactive_border
    layout = dwindle
    allow_tearing = true
}

decoration {
    rounding = 12
    active_opacity = 1.0
    inactive_opacity = 1.0

    shadow {
        enabled = true
        range = 12
        render_power = 3
        color = rgba(11111b99)
    }

    blur {
        enabled = true
        size = 6
        passes = 2
        xray = true
        ignore_opacity = true
    }
}

animations {
    enabled = true
    bezier = fluent, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0

    animation = windows, 1, 4, fluent, slide
    animation = windowsOut, 1, 4, fluent, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 60, linear, loop
    animation = fade, 1, 4, default
    animation = workspaces, 1, 4, fluent, slide
}

dwindle {
    preserve_split = true
}

misc {
    vrr = 2
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}

windowrule = immediate on, match:class ^(steam_app_.*)$
windowrule = opacity 0.90 0.82, match:class ^(kitty)$
windowrule = opacity 0.92 0.85, match:class ^(thunar)$
windowrule = float on, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = float on, match:class ^(blueman-manager)$
windowrule = float on, match:class ^(nm-connection-editor)$
windowrule = float on, match:class ^(zenity)$

layerrule = blur on, ignore_alpha 0, match:namespace waybar
layerrule = blur on, ignore_alpha 0, match:namespace notifications
layerrule = blur on, ignore_alpha 0, match:namespace rofi

$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = CTRL ALT, T, exec, kitty
bind = $mainMod, Q, killactive,
bind = ALT, F4, killactive,
bind = $mainMod, E, exec, thunar
bind = $mainMod, B, exec, xdg-open https://
bind = CTRL SHIFT, Escape, exec, kitty -e btop
bind = $mainMod, V, togglefloating,
bind = $mainMod, F, fullscreen, 0
bind = $mainMod, M, fullscreen, 1
bind = $mainMod, D, exec, rofi -show drun -show-icons
bind = $mainMod, C, exec, cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
bind = $mainMod, N, exec, dunstctl set-paused toggle
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, X, exec, ~/.local/bin/powermenu.sh
bind = CTRL ALT, Delete, exec, ~/.local/bin/powermenu.sh
bind = $mainMod SHIFT, W, exec, ~/.local/bin/wallpaper-rotator.sh --force
bind = $mainMod SHIFT, M, exit,

bind = ALT, Tab, cyclenext,
bind = ALT, Tab, bringactivetotop,
bind = $mainMod, Tab, togglespecialworkspace, magic
bind = $mainMod SHIFT, Tab, movetoworkspace, special:magic

bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim -g "$(slurp)" - | swappy -f -
bind = CTRL, Print, exec, grim ~/Pictures/Screenshots/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png

bindel = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
bindel = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
bindl  = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle
bindl  = , XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle
bindel = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise
bindel = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower
bindl  = , XF86AudioPlay, exec, playerctl play-pause
bindl  = , XF86AudioNext, exec, playerctl next
bindl  = , XF86AudioPrev, exec, playerctl previous

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

binde = $mainMod CTRL, left, resizeactive, -40 0
binde = $mainMod CTRL, right, resizeactive, 40 0
binde = $mainMod CTRL, up, resizeactive, 0 -40
binde = $mainMod CTRL, down, resizeactive, 0 40

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

cat << 'EOF' > ~/.config/waybar/config.jsonc
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "margin-top": 6,
    "margin-left": 10,
    "margin-right": 10,
    "spacing": 6,

    "modules-left": [
        "custom/launcher",
        "hyprland/workspaces",
        "wlr/taskbar"
    ],
    "modules-center": [
        "clock"
    ],
    "modules-right": [
        "group/tray-expander",
        "custom/clipboard",
        "custom/notification",
        "hyprland/language",
        "backlight",
        "pulseaudio",
        "bluetooth",
        "network",
        "cpu",
        "memory",
        "battery",
        "custom/power"
    ],

    "custom/launcher": {
        "format": " \uf303 ",
        "on-click": "rofi -show drun -show-icons",
        "tooltip-format": "Applications (Super+D)"
    },

    "hyprland/workspaces": {
        "on-click": "activate",
        "active-only": false,
        "all-outputs": true,
        "format": "{name}"
    },

    "wlr/taskbar": {
        "format": "{icon}",
        "icon-size": 18,
        "tooltip-format": "{title}",
        "on-click": "activate",
        "on-click-middle": "close"
    },

    "clock": {
        "interval": 1,
        "format": "\udb82\udd54  {:%H:%M   \udb80\udced  %d/%m/%Y}",
        "tooltip-format": "<big>{:%A, %d/%m/%Y}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "group/tray-expander": {
        "orientation": "inherit",
        "drawer": {
            "transition-duration": 250,
            "children-class": "tray-group-item"
        },
        "modules": [
            "custom/tray-icon",
            "tray"
        ]
    },

    "custom/tray-icon": {
        "format": "\udb80\udc41",
        "tooltip-format": "System Tray"
    },

    "tray": {
        "icon-size": 18,
        "spacing": 8
    },

    "custom/clipboard": {
        "format": "\udb80\udc4c",
        "on-click": "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy",
        "on-click-right": "cliphist wipe",
        "tooltip-format": "Left-click: Clipboard History | Right-click: Clear"
    },

    "custom/notification": {
        "exec": "~/.local/bin/dunst-status.sh",
        "interval": 2,
        "on-click": "dunstctl history-pop",
        "on-click-right": "dunstctl set-paused toggle",
        "on-click-middle": "dunstctl close-all",
        "tooltip-format": "Left: History | Right: Do Not Disturb | Middle: Clear All"
    },

    "hyprland/language": {
        "format": "\udb80\udf0c  {}",
        "format-en": "US",
        "format-gr": "GR",
        "on-click": "hyprctl switchxkblayout all next"
    },

    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["\udb80\udcde", "\udb80\udcdf", "\udb80\udce0"],
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    },

    "pulseaudio": {
        "format": "{icon} {volume}% {format_source}",
        "format-muted": "\udb81\udf5f Muted {format_source}",
        "format-source": "\udb80\udf6c",
        "format-source-muted": "\udb80\udf6d",
        "format-icons": {
            "default": ["\udb81\udd7f", "\udb81\udd80", "\udb81\udd7e"]
        },
        "on-click": "pavucontrol",
        "on-click-right": "pamixer -t",
        "on-click-middle": "pamixer --default-source -t",
        "on-scroll-up": "swayosd-client --output-volume raise",
        "on-scroll-down": "swayosd-client --output-volume lower"
    },

    "bluetooth": {
        "format": "\udb80\udcaf",
        "format-disabled": "\udb80\udcb2",
        "format-connected": "\udb80\udcb1 {device_alias}",
        "tooltip-format": "{controller_alias}\n\n{device_enumerate}",
        "tooltip-format-enumerate-connected": "{device_alias}",
        "on-click": "blueman-manager",
        "on-click-right": "rfkill toggle bluetooth"
    },

    "network": {
        "interval": 3,
        "format-wifi": "\udb82\udd28  {essid}",
        "format-ethernet": "\udb80\ude00  Wired",
        "format-disconnected": "\udb82\udd2d  Offline",
        "tooltip-format-wifi": "{ifname}: {ipaddr}/{cidr}\nSignal: {signalStrength}% ({frequency}MHz)\nDown: {bandwidthDownBits} | Up: {bandwidthUpBits}",
        "tooltip-format-ethernet": "{ifname}: {ipaddr}/{cidr}\nDown: {bandwidthDownBits} | Up: {bandwidthUpBits}",
        "tooltip-format-disconnected": "Disconnected",
        "on-click": "nm-connection-editor",
        "on-click-right": "kitty -e nmtui"
    },

    "cpu": {
        "format": "\udb83\udee0 {usage}%",
        "interval": 3,
        "on-click": "kitty -e btop"
    },

    "memory": {
        "format": "\udb80\udf5b {percentage}%",
        "interval": 3,
        "on-click": "kitty -e btop"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "\udb80\udc84 {capacity}%",
        "format-plugged": "\udb81\udea5 {capacity}%",
        "format-icons": ["\udb80\udc7a", "\udb80\udc7c", "\udb80\udc7e", "\udb80\udc80", "\udb80\udc79"]
    },

    "custom/power": {
        "format": "\u23fb",
        "on-click": "~/.local/bin/powermenu.sh",
        "tooltip-format": "Power Menu (Super+X)"
    }
}
EOF

cat << 'EOF' > ~/.config/waybar/style.css
@import "colors.css";

* {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
    font-weight: 600;
    border: none;
    border-radius: 12px;
}

window#waybar {
    background-color: @bg_main;
    color: @fg_main;
    border: 1px solid @accent_primary;
}

#custom-launcher {
    color: @accent_primary;
    font-size: 16px;
    padding: 0 10px;
}

#workspaces button {
    padding: 0 8px;
    color: #7f849c;
    background: transparent;
}

#workspaces button.active {
    color: @bg_main;
    background: @accent_primary;
    border-radius: 8px;
}

#taskbar button {
    padding: 0 6px;
    margin: 2px;
    border-radius: 8px;
}

#taskbar button.active {
    background-color: rgba(203, 166, 247, 0.25);
}

#clock,
#custom-tray-icon,
#tray,
#custom-clipboard,
#custom-notification,
#language,
#backlight,
#pulseaudio,
#bluetooth,
#network,
#cpu,
#memory,
#battery,
#custom-power {
    padding: 0 10px;
    margin: 4px 2px;
    background-color: @bg_module;
    border-radius: 8px;
}

#custom-tray-icon {
    color: @accent_primary;
}

#custom-notification {
    color: @accent_pink;
}

#language {
    color: @accent_yellow;
}

#backlight {
    color: @accent_yellow;
}

#pulseaudio {
    color: @accent_secondary;
}

#bluetooth {
    color: @accent_primary;
}

#network {
    color: @accent_green;
}

#battery.warning {
    color: @accent_yellow;
}

#battery.critical {
    color: @accent_red;
}

#custom-power {
    color: @accent_red;
    padding: 0 12px;
}
EOF

cat << 'EOF' > ~/.config/dunst/dunstrc
[global]
    font = JetBrainsMono Nerd Font 10
    width = 340
    height = (0, 140)
    origin = top-right
    offset = (14, 14)
    frame_width = 2
    frame_color = "#89b4fa"
    corner_radius = 12
    padding = 12
    horizontal_padding = 14
    background = "#1e1e2ee0"
    foreground = "#cdd6f4"

[urgency_low]
    background = "#1e1e2ee0"
    foreground = "#a6adc8"
    frame_color = "#45475a"
    timeout = 4

[urgency_normal]
    background = "#1e1e2ee0"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout = 6

[urgency_critical]
    background = "#1e1e2ef5"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
    timeout = 0
EOF

cat << 'EOF' > ~/.config/rofi/config.rasi
configuration {
    modi: "drun,run";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "JetBrainsMono Nerd Font 11";
    drun-display-format: "{name}";
}

@theme "/dev/null"
@import "colors.rasi"

* {
    background-color: transparent;
    text-color: @fg;
}

window {
    width: 520px;
    background-color: @bg;
    border: 2px;
    border-color: @accent;
    border-radius: 12px;
    padding: 16px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 8px;
    padding: 10px;
    margin: 0 0 12px 0;
}

prompt {
    text-color: @accent;
    margin: 0 10px 0 0;
}

listview {
    lines: 8;
    columns: 1;
    fixed-height: false;
    spacing: 6px;
}

element {
    padding: 8px 12px;
    border-radius: 8px;
}

element selected {
    background-color: @accent;
    text-color: #1e1e2e;
}

element-icon {
    size: 24px;
    margin: 0 10px 0 0;
}
EOF

cat << 'EOF' > ~/.config/kitty/kitty.conf
font_family      JetBrainsMono Nerd Font
font_size        11.0
window_padding_width 10
confirm_os_window_close 0

include colors.conf
EOF

if ! grep -q "start-hyprland" ~/.bash_profile 2>/dev/null; then
    cat << 'EOF' >> ~/.bash_profile

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "${XDG_VTNR:-0}" -eq 1 ]]; then
    exec start-hyprland
fi
EOF
fi

chmod +x "Finish.sh"
echo "Executing Finish.sh"
"./Finish.sh"
