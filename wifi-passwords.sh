#!/usr/bin/env bash
# wifi-passwords.sh — dumps all saved Wi-Fi passwords to saved.txt
# Supports: Linux (NetworkManager) | macOS (Keychain)
# Usage: bash wifi-passwords.sh

OUT="saved.txt"
COUNT=0

# ── Helpers ────────────────────────────────────────────────────────────────────

write_header() {
    {
        echo "WiFi Saved Passwords"
        echo "Generated: $(date)"
        echo "System:    $(uname -srm)"
        echo "========================================"
        echo ""
    } > "$OUT"
}

add_entry() {
    local ssid="$1"
    local pass="$2"
    {
        echo "SSID:     $ssid"
        echo "Password: $pass"
        echo ""
    } >> "$OUT"
    COUNT=$((COUNT + 1))
}

# ── Linux ──────────────────────────────────────────────────────────────────────

linux_dump() {
    # Method 1: nmcli (NetworkManager CLI — most reliable, no sudo needed for own user)
    if command -v nmcli &>/dev/null; then
        echo "[*] Using nmcli..."
        while IFS= read -r ssid; do
            [ -z "$ssid" ] && continue
            pass=$(nmcli -s -g 802-11-wireless-security.psk connection show "$ssid" 2>/dev/null)
            [ -n "$pass" ] && add_entry "$ssid" "$pass"
        done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null \
                   | grep ':802-11-wireless$' \
                   | cut -d: -f1)
        return
    fi

    # Method 2: Read NetworkManager config files directly (needs sudo)
    NM_DIR="/etc/NetworkManager/system-connections"
    if [ -d "$NM_DIR" ]; then
        echo "[*] Reading NetworkManager files (may need sudo)..."
        for f in "$NM_DIR"/*; do
            [ -f "$f" ] || continue
            ssid=$(grep -m1 "^ssid=" "$f" 2>/dev/null | cut -d= -f2-)
            psk=$(grep -m1 "^psk=" "$f" 2>/dev/null | cut -d= -f2-)
            [ -n "$ssid" ] && [ -n "$psk" ] && add_entry "$ssid" "$psk"
        done
        return
    fi

    # Method 3: wpa_supplicant fallback (older/embedded Linux)
    for conf in /etc/wpa_supplicant/wpa_supplicant.conf \
                /etc/wpa_supplicant.conf \
                /data/misc/wifi/wpa_supplicant.conf; do
        [ -f "$conf" ] || continue
        echo "[*] Reading $conf..."
        while IFS= read -r line; do
            case "$line" in
                *ssid=*)   current_ssid=$(echo "$line" | cut -d'"' -f2) ;;
                *psk=*)    current_psk=$(echo "$line" | cut -d'"' -f2)
                           [ -n "$current_ssid" ] && [ -n "$current_psk" ] \
                               && add_entry "$current_ssid" "$current_psk"
                           ;;
            esac
        done < "$conf"
        return
    done

    echo "[-] No supported password store found on this Linux system."
}

# ── macOS ──────────────────────────────────────────────────────────────────────

mac_dump() {
    echo "[*] Reading macOS Keychain (you may see access prompts)..."

    # Get list of preferred wireless networks
    # Try en0 (Wi-Fi), fall back to en1
    local iface=""
    for i in en0 en1 en2; do
        if networksetup -listallhardwareports 2>/dev/null | grep -A1 "Wi-Fi" | grep -q "$i"; then
            iface="$i"
            break
        fi
    done
    [ -z "$iface" ] && iface="en0"

    local networks
    networks=$(networksetup -listpreferredwirelessnetworks "$iface" 2>/dev/null \
                | grep -v "Preferred Networks" \
                | sed 's/^[[:space:]]*//' \
                | grep -v "^$")

    if [ -z "$networks" ]; then
        echo "[-] No preferred networks found for interface $iface"
        return
    fi

    while IFS= read -r ssid; do
        [ -z "$ssid" ] && continue
        pass=$(security find-generic-password \
                   -D "AirPort network password" \
                   -wa "$ssid" 2>/dev/null)
        [ -n "$pass" ] && add_entry "$ssid" "$pass"
    done <<< "$networks"
}

# ── Main ───────────────────────────────────────────────────────────────────────

OS=$(uname -s 2>/dev/null)

echo ""
echo "  WiFi Password Dumper"
echo "  ===================="
echo ""

write_header

case "$OS" in
    Linux)
        linux_dump
        ;;
    Darwin)
        mac_dump
        ;;
    *)
        echo "[-] Unsupported OS: $OS"
        echo "    Run wifi-passwords.bat on Windows."
        exit 1
        ;;
esac

echo ""
if [ "$COUNT" -gt 0 ]; then
    echo "[+] Found $COUNT saved password(s) → $OUT"
else
    echo "[-] No saved Wi-Fi passwords found."
    echo "    If on Linux, try running with: sudo bash wifi-passwords.sh"
fi
echo ""
