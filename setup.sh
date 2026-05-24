#!/bin/bash

# =======================================================
#   IRTx Red Team - Team Setup Script
#   Run this first on every Kali machine on IRTx day
#   Usage: sudo bash setup.sh
# =======================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${RED}"
echo "  ██████╗ ███████╗██████╗     ████████╗███████╗ █████╗ ███╗   ███╗"
echo "  ██╔══██╗██╔════╝██╔══██╗       ██║   ██╔════╝██╔══██╗████╗ ████║"
echo "  ██████╔╝█████╗  ██║  ██║       ██║   █████╗  ███████║██╔████╔██║"
echo "  ██╔══██╗██╔══╝  ██║  ██║       ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║"
echo "  ██║  ██║███████╗██████╔╝       ██║   ███████╗██║  ██║██║ ╚═╝ ██║"
echo "  ╚═╝  ╚═╝╚══════╝╚═════╝        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝"
echo -e "${CYAN}          IRTx Red Team — Setup Script${RESET}"
echo -e "${YELLOW}          DataTrust Security Consultants${RESET}"
echo ""

BASE="https://raw.githubusercontent.com/YourUsername/irtx-redteam-scripts/main"

SCRIPTS=(
    "recon_scan.sh"
    "exploit_metasploitable.sh"
    "privesc.sh"
    "exfil.sh"
)

echo -e "${CYAN}[*] Downloading Red Team scripts from GitHub...${RESET}"
echo ""

FAIL=0
for script in "${SCRIPTS[@]}"; do
    echo -ne "  ${YELLOW}[~] Downloading $script ...${RESET}"
    if wget -q "$BASE/$script" -O "$script"; then
        echo -e "\r  ${GREEN}[+] $script — OK${RESET}          "
    else
        echo -e "\r  ${RED}[!] $script — FAILED${RESET}      "
        FAIL=1
    fi
done

echo ""
chmod +x *.sh
echo -e "${GREEN}[+] Permissions set on all scripts.${RESET}"
echo ""

if [ $FAIL -eq 1 ]; then
    echo -e "${RED}[!] One or more scripts failed to download.${RESET}"
    echo -e "${YELLOW}    Check your internet connection or GitHub URL.${RESET}"
else
    echo -e "${BOLD}${GREEN}  All scripts downloaded and ready to run!${RESET}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}  Available scripts:${RESET}"
for script in "${SCRIPTS[@]}"; do
    echo -e "    ${GREEN}►${RESET} sudo ./$script"
done
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
