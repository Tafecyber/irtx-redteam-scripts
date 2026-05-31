#!/bin/bash

# =======================================================
#   IRTx Red Team - Reconnaissance Script 
#   Author: DataTrust Red Team
#   Description: Fast host discovery, stealth port scan,
#                coloured output and per-host reporting.
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
echo -e "${YELLOW}            DataBreach${RESET}"
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

# --- Auto-detect interface and attacker IP ---
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
ATTACKER_IP=$(ip -4 addr show "$INTERFACE" | grep inet | awk '{print $2}' | cut -d'/' -f1)

if [ -z "$INTERFACE" ]; then
    echo -e "${RED}[!] Could not detect network interface. Exiting.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Interface : ${BOLD}$INTERFACE${RESET}"
echo -e "${CYAN}[*] Attacker  : ${BOLD}$ATTACKER_IP${RESET}"
echo ""

# --- Input validation ---
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
echo -e "${YELLOW}[?] Enter target network (e.g. 10.30.0.0/24):${RESET}"
read -r TARGET_NETWORK

if [ -z "$TARGET_NETWORK" ]; then
    echo -e "${RED}[!] No target provided. Exiting.${RESET}"
    exit 1
fi

IFS='/' read -r ip_part cidr_part <<< "$TARGET_NETWORK"

if ! validate_ip "$ip_part"; then
    echo -e "${RED}[!] Invalid IP: $ip_part${RESET}"
    exit 1
fi

if ! validate_cidr "$cidr_part"; then
    echo -e "${RED}[!] Invalid CIDR: /$cidr_part${RESET}"
    exit 1
fi

# --- Output setup ---
TIMESTAMP=$(date +%F_%H-%M-%S)
LIVE_HOSTS="live_hosts_$TIMESTAMP.txt"
REPORT_DIR="recon_report_$TIMESTAMP"
FULL_REPORT="$REPORT_DIR/full_report_$TIMESTAMP.txt"
mkdir -p "$REPORT_DIR"

# =======================================================
# PHASE 1: HOST DISCOVERY
# TCP SYN probes on key ports catches Windows hosts
# that silently drop ICMP (ping) packets.
# -sn  : No port scan, discovery only
# -PS  : TCP SYN probe to listed ports
# -PE  : ICMP echo probe (catches Linux/routers)
# -n   : No DNS resolution (faster, quieter)
# -T3  : Default timing
# =======================================================
echo -e "${MAGENTA}[>] Phase 1: Host Discovery ...${RESET}"
echo -e "${CYAN}[*] Probing with TCP SYN on ports 22,80,135,139,443,445,3389 + ICMP${RESET}"
echo ""

nmap -sn \
    -PS22,80,135,139,443,445,3389 \
    -PE \
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
echo ""

# =======================================================
# PHASE 2: SINGLE STEALTH PORT SCAN (all hosts, one call)
# Targets high-value and commonly vulnerable ports.
# -sS  : SYN stealth scan (half-open TCP)
# -sV  : Service and version detection
# -O   : OS fingerprinting
# -T3  : Moderate Speed
# --open : Only show open ports (cleaner output)
# -oN  : Save to file in normal nmap format
# =======================================================
echo -e "${MAGENTA}[>] Phase 2: Stealth Port & Service Scan (one pass across all hosts) ...${RESET}"
echo -e "${CYAN}[*] Ports: 21,22,23,25,53,80,110,135,139,443,445,${RESET}"
echo -e "${CYAN}           1433,1521,2222,3306,3389,4444,5900,6667,8080,8443,9200,10000${RESET}"
echo ""

HOSTS_INLINE=$(paste -sd' ' "$LIVE_HOSTS")

nmap -sS -sV -O \
    -p 21,22,23,25,53,80,110,135,139,443,445,1433,1521,2222,3306,3389,4444,5900,6667,8080,8443,9200,10000 \
    -n \
    -T3 \
    --open \
    $HOSTS_INLINE \
    -oN "$FULL_REPORT"

# =======================================================
# PHASE 3: PARSE OUTPUT — coloured screen summary
#          + individual per-host .txt report files
# =======================================================
echo ""
echo -e "${MAGENTA}[>] Phase 3: Building Reports ...${RESET}"
echo ""

CURRENT_HOST=""
CURRENT_FILE=""

while IFS= read -r line; do

    # New host block detected
    if [[ "$line" =~ ^"Nmap scan report for" ]]; then
        CURRENT_HOST=$(echo "$line" | awk '{print $NF}' | tr -d '()')
        CURRENT_FILE="$REPORT_DIR/host_${CURRENT_HOST}.txt"

        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}${GREEN}  Target : $CURRENT_HOST${RESET}"
        echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        {
            echo "============================================="
            echo "  Target: $CURRENT_HOST"
            echo "  Scanned: $(date)"
            echo "============================================="
        } > "$CURRENT_FILE"

    # OS detection line
    elif [[ "$line" =~ "OS details:" ]]; then
        echo -e "  ${YELLOW}[OS]  ${line}${RESET}"
        echo "  $line" >> "$CURRENT_FILE"

    # Running OS guess
    elif [[ "$line" =~ "Running:" ]]; then
        echo -e "  ${YELLOW}[OS]  ${line}${RESET}"
        echo "  $line" >> "$CURRENT_FILE"

    # Open port line
    elif echo "$line" | grep -q "open"; then
        PORT=$(echo "$line" | awk '{print $1}')
        PROTO=$(echo "$line" | awk '{print $2}')
        SERVICE=$(echo "$line" | awk '{print $3}')
        VERSION=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | xargs)
        echo -e "  ${GREEN}[OPEN]${RESET} ${BOLD}$PORT${RESET} ($PROTO) — ${CYAN}$SERVICE${RESET} $VERSION"
        echo "  [OPEN] $PORT ($PROTO) — $SERVICE $VERSION" >> "$CURRENT_FILE"

    # Host up line
    elif [[ "$line" =~ "Host is up" ]]; then
        LATENCY=$(echo "$line" | grep -oP '\(.*?\)')
        echo -e "  ${GREEN}[UP]${RESET} Host is up $LATENCY"
        echo "  [UP] Host is up $LATENCY" >> "$CURRENT_FILE"

    # Write all other lines to file only (keeps screen clean)
    else
        [ -n "$CURRENT_FILE" ] && echo "$line" >> "$CURRENT_FILE"
    fi

done < "$FULL_REPORT"

# =======================================================
# FINAL SUMMARY
# =======================================================
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  All scans complete!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Hosts found    :${RESET} ${BOLD}$HOST_COUNT${RESET}"
echo -e "  ${YELLOW}Live hosts file:${RESET} $LIVE_HOSTS"
echo -e "  ${YELLOW}Full report    :${RESET} $FULL_REPORT"
echo -e "  ${YELLOW}Per-host files :${RESET} $REPORT_DIR/host_<IP>.txt"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

exit 0
