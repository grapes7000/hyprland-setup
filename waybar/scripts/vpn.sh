#!/bin/sh
# VPN/IP indicator for waybar. Detects OpenVPN/WireGuard (tun0/wg0).
vpn_if=$(ip -o -4 addr show 2>/dev/null | awk '/tun[0-9]|wg[0-9]/{print $2; exit}')
if [ -n "$vpn_if" ]; then
    ip=$(ip -o -4 addr show "$vpn_if" | awk '{print $4}' | cut -d/ -f1)
    printf '{"text":"  %s","class":"protected","tooltip":"VPN up (%s)"}\n' "$ip" "$vpn_if"
else
    ip=$(ip -o -4 addr show 2>/dev/null | awk '!/ lo /{print $4}' | cut -d/ -f1 | head -1)
    printf '{"text":"  %s","class":"exposed","tooltip":"No VPN — traffic exposed"}\n' "$ip"
fi
