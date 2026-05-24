#!/bin/bash

# =======================================================
#   IRTx Red Team - Reconnaissance Script
#   Author: DataTrust Red Team
#   Description: Stealthy host discovery and port scan
#                with coloured output and report gen.
# =======================================================

# --- Colours ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Banner ---
echo -e "${RED}"
echo "  ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗"
echo "  ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║"
echo "  ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║"
echo "  ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║"
echo "  ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║"
echo "  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝"
echo -e "${CYAN}       IRTx Red Team Reconnaissance Tool${RESET}"
echo -e "${YELLOW}       DataTrust Security Consultants${RESET}"
echo ""

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root. Use sudo.${RESET}"
    exit 1
fi

# --- nmap check ---
if ! command -v nmap &> /dev/null; then
    echo -e "${RED}[!] nmap is not installed. Run: sudo apt install nmap${RESET}"
    exit 1
fi

# --- Auto-detect interface ---
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}[!] Could not auto-detect network interface. Exiting.${RESET}"
    exit 1
fi
echo -e "${CYAN}[*] Interface detected: ${BOLD}$INTERFACE${RESET}"

# --- Get attacker IP for decoy list ---
ATTACKER_IP=$(ip -4 addr show "$INTERFACE" | grep inet | awk '{print $2}' | cut -d'/' -f1)
echo -e "${CYAN}[*] Attacker IP: ${BOLD}$ATTACKER_IP${RESET}"

# --- Input validation functions ---
validate_ip() {
    local ip=$1
    IFS='.' read -r -a octets <<< "$ip"
    [ ${#octets[@]} -ne 4 ] && return 1
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

# --- Prompt for target ---
echo ""
echo -e "${YELLOW}[?] Enter target network (e.g. 10.30.0.0/24):${RESET}"
read -r TARGET_NETWORK

if [ -z "$TARGET_NETWORK" ]; then
    echo -e "${RED}[!] No target provided. Exiting.${RESET}"
    exit 1
fi

IFS='/' read -r ip_part cidr_part <<< "$TARGET_NETWORK"

if ! validate_ip "$ip_part"; then
    echo -e "${RED}[!] Invalid IP address: $ip_part${RESET}"
    exit 1
fi

if ! validate_cidr "$cidr_part"; then
    echo -e "${RED}[!] Invalid CIDR: /$cidr_part (must be 0-32)${RESET}"
    exit 1
fi

# --- Setup output files ---
TIMESTAMP=$(date +%F_%H-%M-%S)
LIVE_HOSTS="live_hosts_$TIMESTAMP.txt"
REPORT_DIR="recon_report_$TIMESTAMP"
FULL_REPORT="$REPORT_DIR/full_report_$TIMESTAMP.txt"
mkdir -p "$REPORT_DIR"

# =======================================================
# PHASE 1: HOST DISCOVERY
# Uses TCP SYN + ICMP + ARP probes to catch hosts that
# block ICMP (e.g. Windows with firewall enabled).
# Decoys and MAC spoofing used to confuse blue team logs.
# =======================================================
echo ""
echo -e "${MAGENTA}[>] Phase 1: Host Discovery on $TARGET_NETWORK ...${RESET}"
echo -e "${CYAN}[*] Using TCP SYN + ICMP + ARP probes (catches Windows hosts that block ping)${RESET}"

nmap -sn \
    -PS22,80,135,443,445,3389 \
    -PA80,445 \
    -PE \
    -D RND:5 \
    --spoof-mac 0 \
    -e "$INTERFACE" \
    -n \
    -T3 \
    "$TARGET_NETWORK" \
    | grep "Nmap scan report for" \
    | awk '{print $NF}' \
    | tr -d '()' \
    | sort -t. -k4 -n > "$LIVE_HOSTS"

# --- Check results ---
if [ ! -s "$LIVE_HOSTS" ]; then
    echo -e "${RED}[-] No live hosts found on $TARGET_NETWORK. Exiting.${RESET}"
    rm -f "$LIVE_HOSTS"
    exit 1
fi

HOST_COUNT=$(wc -l < "$LIVE_HOSTS")
echo -e "${GREEN}[+] Found ${BOLD}$HOST_COUNT${RESET}${GREEN} live host(s):${RESET}"
while IFS= read -r host; do
    echo -e "    ${GREEN}►  $host${RESET}"
done < "$LIVE_HOSTS"

# =======================================================
# PHASE 2: SINGLE COMBINED STEALTH SCAN
# One nmap call across all live hosts simultaneously.
# Covers common + high-value ports.
# -sS  : SYN stealth (half-open, avoids full handshake)
# -sV  : Service/version detection
# -O   : OS fingerprinting
# -A   : Aggressive detection (scripts, traceroute)
# -D   : Random decoys to flood blue team logs
# =======================================================
echo ""
echo -e "${MAGENTA}[>] Phase 2: Stealth Port & Service Scan (single nmap pass) ...${RESET}"
echo -e "${CYAN}[*] Scanning ports: 21,22,23,25,53,80,110,135,139,443,445,${RESET}"
echo -e "${CYAN}    1433,1521,3306,3389,4444,5900,6667,8080,8443,9200${RESET}"

# Build space-separated host list for nmap
HOSTS_INLINE=$(paste -sd' ' "$LIVE_HOSTS")

nmap \
    -sS -sV -O -A \
    -p 21,22,23,25,53,80,110,135,139,443,445,1433,1521,3306,3389,4444,5900,6667,8080,8443,9200 \
    -D RND:5 \
    --spoof-mac 0 \
    -e "$INTERFACE" \
    -n \
    -T3 \
    --open \
    $HOSTS_INLINE \
    -oN "$FULL_REPORT"

# =======================================================
# PHASE 3: COLOURED SUMMARY REPORT (per host)
# Parses the nmap output and prints a clean summary
# to screen, then saves individual host reports.
# =======================================================
echo ""
echo -e "${MAGENTA}[>] Phase 3: Generating Per-Host Reports ...${RESET}"

CURRENT_HOST=""
CURRENT_FILE=""

while IFS= read -r line; do
    # Detect new host block
    if [[ "$line" =~ ^"Nmap scan report for" ]]; then
        CURRENT_HOST=$(echo "$line" | awk '{print $NF}' | tr -d '()')
        CURRENT_FILE="$REPORT_DIR/host_${CURRENT_HOST}.txt"
        echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${GREEN}  Host: $CURRENT_HOST${RESET}"
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo "=== Host: $CURRENT_HOST ===" > "$CURRENT_FILE"

    # Detect OS line
    elif [[ "$line" =~ "OS details:" || "$line" =~ "Running:" ]]; then
        echo -e "  ${YELLOW}$line${RESET}"
        echo "$line" >> "$CURRENT_FILE"

    # Detect open ports
    elif [[ "$line" =~ "open" ]]; then
        PORT=$(echo "$line" | awk '{print $1}')
        SERVICE=$(echo "$line" | awk '{print $3}')
        VERSION=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | xargs)
        echo -e "  ${GREEN}[OPEN]${RESET} ${BOLD}$PORT${RESET} — $SERVICE $VERSION"
        echo "  [OPEN] $PORT — $SERVICE $VERSION" >> "$CURRENT_FILE"

    # Write everything to individual file anyway
    else
        [ -n "$CURRENT_FILE" ] && echo "$line" >> "$CURRENT_FILE"
    fi

done < "$FULL_REPORT"

# =======================================================
# FINAL SUMMARY
# =======================================================
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Scan Complete!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Live hosts file :${RESET} $LIVE_HOSTS"
echo -e "  ${YELLOW}Full report     :${RESET} $FULL_REPORT"
echo -e "  ${YELLOW}Per-host reports:${RESET} $REPORT_DIR/host_<IP>.txt"
echo -e "  ${YELLOW}Hosts scanned   :${RESET} $HOST_COUNT"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

exit 0
