#!/bin/bash
# Display currently running applications as icons

get_app_icon() {
    case "$1" in
        firefox) echo "" ;;
        chromium|google-chrome|brave) echo "" ;;
        kitty|alacritty|wezterm) echo "" ;;
        code|vscode) echo "" ;;
        thunar|nautilus|dolphin) echo "" ;;
        vlc|mpv) echo "" ;;
        discord|slack) echo "" ;;
        spotify|deadbeef) echo "" ;;
        steam) echo "" ;;
        *) echo "" ;;
    esac
}

# Get list of running applications
apps=$(hyprctl clients -j 2>/dev/null | jq -r '.[].class' | sort -u)

if [ -z "$apps" ]; then
    echo ""
    exit 0
fi

icons=""
count=0
for app in $apps; do
    # Skip some apps we don't want to show
    if [[ "$app" =~ ^(waybar|Hyprland|xdg-desktop)$ ]]; then
        continue
    fi

    icon=$(get_app_icon "$app")
    icons="$icons $icon"
    ((count++))

    # Limit to 8 apps to avoid clutter
    if [ $count -ge 8 ]; then
        icons="$icons …"
        break
    fi
done

echo "${icons:1}"  # Remove leading space
