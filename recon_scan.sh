#!/bin/bash

# -------------------------------------------------------
# PHASE 1: VALIDATION
# Ensures the script is run as root (required for raw
# packet crafting used in stealth scanning)
# -------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Checks nmap is installed before proceeding
if ! command -v nmap &> /dev/null; then
    echo "nmap is not installed. Please install it."
    exit 1
fi

# Validates the user-supplied IPv4 address (4 octets, 0-255 each)
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

# Validates the CIDR suffix (0-32)
validate_cidr() {
    local cidr=$1
    if ! [[ "$cidr" =~ ^[0-9]+$ ]] || \
       [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        return 1
    fi
    return 0
}

# -------------------------------------------------------
# PHASE 2: HOST DISCOVERY (Ping Sweep with Decoys)
# Uses nmap -sn (no port scan) to find live hosts only.
#
# Key evasion flags:
#   -D  : Decoy scan — spoofs traffic as coming from
#         multiple blue team IPs to confuse IDS/SIEM logs
#   --spoof-mac : Spoofs the MAC address of the sender
#   -n  : No DNS resolution (faster, leaves fewer logs)
# -------------------------------------------------------
TIMESTAMP=$(date +%F_%H-%M-%S)
NMAP_OUTPUT_DIR="nmap_scans_$TIMESTAMP"
LIVE_HOSTS="live_hosts_$TIMESTAMP.txt"
mkdir -p "$NMAP_OUTPUT_DIR"

nmap -sn \
  -D 192.168.0.114,192.168.0.115,192.168.0.116,192.168.0.117,192.168.0.118 \
  --spoof-mac 00:50:56:9D:E3:F9 \
  -n "$TARGET_NETWORK" \
  | grep "Nmap scan report for" \
  | awk '{print $5}' \
  | sort -u > "$LIVE_HOSTS"

# -------------------------------------------------------
# PHASE 3: STEALTH PORT & SERVICE SCAN (Parallel)
# Runs a full scan against each discovered live host.
#
# Key flags:
#   -sS : SYN stealth scan (half-open, harder to detect)
#   -sV : Service version detection
#   -O  : OS fingerprinting
#   -p  : Port range (1-1000 common + 3000-4000 for web/dev)
#   -D  : Decoys again, different spoofed MAC this time
#   xargs -P 5 : Runs 5 parallel scans (one per live host)
#   -oN : Saves output per host to individual .txt files
# -------------------------------------------------------
cat "$LIVE_HOSTS" | xargs -P 5 -I {} nmap -n \
  -p 1-1000,3000-4000 \
  -D 192.168.0.114,192.168.0.115,192.168.0.116,192.168.0.117,192.168.0.118 \
  --spoof-mac 00:50:56:9D:3C:C6 \
  -sS -sV -O \
  --hosttimeout 5m {} \
  -oN "$NMAP_OUTPUT_DIR/nmap_scan_{}.txt"

echo "All scans completed. Results stored in $NMAP_OUTPUT_DIR/"
exit 0
