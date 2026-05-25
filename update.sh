#!/bin/bash

# =============================================================
# IRTx Red Team - Kali Quick Prep Script
# DataBreach | Red Team Playbook
# =============================================================

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
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

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./prep.sh${RESET}"
  exit 1
fi

# =============================================================
# STEP 1 — System Update & Upgrade
# =============================================================
echo -e "${YELLOW}[+] Updating system...${RESET}"
apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
apt-get autoremove -y && apt-get autoclean -y
echo -e "${GREEN}[✓] System updated.${RESET}"
echo ""

# =============================================================
# STEP 2 — Install Tools
# =============================================================
echo -e "${YELLOW}[+] Installing Red Team tools...${RESET}"

TOOLS=(
  nmap
  metasploit-framework
  smbclient
  enum4linux
  gobuster
  dirb
  nikto
  hydra
  john
  hashcat
  crackmapexec
  evil-winrm
  impacket-scripts
  bloodhound
  neo4j
  responder
  netcat-traditional
  curl
  wget
  git
  python3
  python3-pip
  proxychains4
  net-tools
  dnsutils
  whois
  tcpdump
  wireshark
  seclists
)

for tool in "${TOOLS[@]}"; do
  echo -e "${CYAN}  [~] Installing: $tool${RESET}"
  apt-get install -y "$tool" > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}  [✓] $tool ready.${RESET}"
  else
    echo -e "${RED}  [!] Failed: $tool${RESET}"
  fi
done
echo ""

# =============================================================
# DONE
# =============================================================
echo -e "${GREEN}"
echo "  ============================================="
echo "   Kali Ready — Good Hunting."
echo "  ============================================="
echo -e "${RESET}"
