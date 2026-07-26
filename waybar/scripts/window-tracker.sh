#!/bin/bash
# Window tracker with nerd font icons based on app class
# Monitors active window and displays icon + title

get_icon() {
    local class="$1"
    case "$class" in
        # Web browsers
        firefox|chromium|google-chrome|brave)
            echo "";;
        # Terminals
        kitty|alacritty|wezterm|xterm)
            echo "";;
        # Editors
        nvim|vim|nano|gedit|mousepad)
            echo "";;
        # IDEs
        code|vscode|jetbrains-*)
            echo "";;
        # File managers
        thunar|nautilus|dolphin|ranger)
            echo "";;
        # Media/Images
        vlc|mpv|feh|krita|gimp)
            echo "";;
        # Chat/Communication
        discord|slack|telegram|element)
            echo "";;
        # PDF/Documents
        zathura|okular|libreoffice|evince)
            echo "";;
        # Music/Audio
        spotify|deadbeef|ncmpcpp)
            echo "";;
        # Settings
        pavucontrol|blueman|nm-applet)
            echo "";;
        # Games
        steam|lutris|gamescope)
            echo "";;
        # System
        htop|bpytop|bashtop)
            echo "";;
        # Office
        libreoffice-writer|libreoffice-calc|libreoffice-impress)
            echo "";;
        # Default
        *)
            echo "";;
    esac
}

# Monitor for window changes using hyprctl
hyprctl dispatch focusmonitor current 2>/dev/null

while true; do
    # Get active window info
    window_info=$(hyprctl activewindow -j 2>/dev/null)

    if [ -z "$window_info" ] || [ "$window_info" = "null" ]; then
        # No active window
        echo ""
        sleep 0.5
        continue
    fi

    class=$(echo "$window_info" | jq -r '.class // empty' 2>/dev/null)
    title=$(echo "$window_info" | jq -r '.title // empty' 2>/dev/null)

    if [ -z "$class" ] && [ -z "$title" ]; then
        echo ""
        sleep 0.5
        continue
    fi

    # Get icon for the app class
    icon=$(get_icon "$class")

    # Truncate title to reasonable length
    max_len=50
    if [ ${#title} -gt $max_len ]; then
        title="${title:0:$max_len}…"
    fi

    # Output: icon + title
    if [ -n "$title" ]; then
        echo "$icon $title"
    else
        echo "$icon"
    fi

    sleep 0.5
done
