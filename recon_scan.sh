#!/bin/bash

# =======================================================
# IRTx Red Team - Reconnaissance Script
# Interface: eth0 (auto-detected)
# Author: Red Team - DataTrust
# =======================================================

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Check nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "nmap is not installed. Please install it (e.g., sudo apt install nmap)."
    exit 1
fi

# Auto-detect active network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "[*] Using interface: $INTERFACE"

# -------------------------------------------------------
# INPUT VALIDATION
# -------------------------------------------------------
validate_ip() {
    local ip=$1
    IFS='.' read -r -a octets <<< "$ip"
    if [ ${#octets[@]} -ne 4 ]; then return 1; fi
    for octet in "${octets[@]}"; do
        if ! [[ "$octet" =~ ^[0-9]+$ ]] || \
           [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
            return 1
        fi
    done
    return 0
}

validate_cidr() {
    local cidr=$1
    if ! [[ "$cidr" =~ ^[0-9]+$ ]] || \
       [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        return 1
    fi
    return 0
}

# Prompt for target network
echo "Please enter the target network (e.g., 10.30.0.0/24):"
read -r TARGET_NETWORK

if [ -z "$TARGET_NETWORK" ]; then
    echo "Error: No target network provided."
    exit 1
fi

IFS='/' read -r ip_part cidr_part <<< "$TARGET_NETWORK"

if ! validate_ip "$ip_part"; then
    echo "Error: '$ip_part' is not a valid IPv4 address."
    exit 1
fi

if ! validate_cidr "$cidr_part"; then
    echo "Error: '/$cidr_part' is not a valid subnet mask (must be 0-32)."
    exit 1
fi

# -------------------------------------------------------
# PHASE 2: HOST DISCOVERY (Ping Sweep with Decoys)
# -------------------------------------------------------
TIMESTAMP=$(date +%F_%H-%M-%S)
NMAP_OUTPUT_DIR="nmap_scans_$TIMESTAMP"
LIVE_HOSTS="live_hosts_$TIMESTAMP.txt"
mkdir -p "$NMAP_OUTPUT_DIR"

echo "[*] Starting host discovery on $TARGET_NETWORK..."

nmap -sn \
    -D 192.168.0.114,192.168.0.115,192.168.0.116,192.168.0.117,192.168.0.118 \
    --spoof-mac 00:50:56:9D:E3:F9 \
    -e "$INTERFACE" \
    -n "$TARGET_NETWORK" \
    | grep "Nmap scan report for" \
    | awk '{print $5}' \
    | sort -u > "$LIVE_HOSTS"

# Check if any live hosts found
if [ ! -s "$LIVE_HOSTS" ]; then
    echo "[-] No live hosts found on $TARGET_NETWORK."
    rm "$LIVE_HOSTS"
    exit 1
fi

echo "[+] Found $(wc -l < "$LIVE_HOSTS") live host(s). Saved to $LIVE_HOSTS"
cat "$LIVE_HOSTS"

# -------------------------------------------------------
# PHASE 3: STEALTH PORT & SERVICE SCAN (Parallel)
# -------------------------------------------------------
echo "[*] Starting stealth scans in parallel..."

cat "$LIVE_HOSTS" | xargs -P 5 -I {} nmap -n \
    -p 1-1000,3000-4000 \
    -D 192.168.0.114,192.168.0.115,192.168.0.116,192.168.0.117,192.168.0.118 \
    --spoof-mac 00:50:56:9D:3C:C6 \
    -e "$INTERFACE" \
    -sS -sV -O \
    --hosttimeout 5m {} \
    -oN "$NMAP_OUTPUT_DIR/nmap_scan_{}.txt"

echo "[+] All scans completed. Results stored in $NMAP_OUTPUT_DIR/"
exit 0
