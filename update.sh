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
echo "  ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗"
echo "  ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝"
echo "  ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  "
echo "  ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  "
echo "  ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗"
echo "   ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝"
echo -e "${CYAN}       IRTx Red Team Prep Tool${RESET}"
echo -e "${YELLOW}            DataBreach${RESET}"
echo ""

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./prep.sh${RESET}"
  exit 1
fi

# =============================================================
# STEP 1 — Set Fast Mirror & Refresh Package List
# =============================================================
echo -e "${YELLOW}[+] Setting Kali mirror...${RESET}"
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" \
  > /etc/apt/sources.list
echo -e "${GREEN}[✓] Mirror set.${RESET}"
echo ""

echo -e "${YELLOW}[+] Refreshing package list...${RESET}"
apt-get update -y > /dev/null 2>&1
echo -e "${GREEN}[✓] Package list updated.${RESET}"
echo ""

# =============================================================
# STEP 2 — Install Tools Only (no system upgrade)
# =============================================================
echo -e "${YELLOW}[+] Installing Red Team tools...${RESET}"

TOOLS=(
  nmap
  metasploit-framework
  netcat-traditional
  hydra
  hping3
  dsniff
  gobuster
  nikto
  python3
  python3-pip
  curl
  burpsuite
  sqlmap
  proxychains4
  john
)

# --- Spinner function ---
spinner() {
  local pid=$1
  local tool=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    printf "\r  ${CYAN}[${spin:$i:1}] Installing: $tool...${RESET}"
    sleep 0.1
  done
  printf "\r"
}

# --- Install loop ---
TOTAL=${#TOOLS[@]}
COUNT=0

for tool in "${TOOLS[@]}"; do
  apt-get install -y "$tool" > /dev/null 2>&1 &
  PID=$!
  spinner "$PID" "$tool"
  wait "$PID"
  COUNT=$((COUNT + 1))
  PERCENT=$(( COUNT * 100 / TOTAL ))
  if [[ $? -eq 0 ]]; then
    echo -e "  ${GREEN}[✓] $tool ready. ${CYAN}($COUNT/$TOTAL — $PERCENT%)${RESET}"
  else
    echo -e "  ${RED}[!] Failed: $tool ${CYAN}($COUNT/$TOTAL — $PERCENT%)${RESET}"
  fi
done
echo ""

# =============================================================
# STEP 3 — Python Modules
# =============================================================
echo -e "${YELLOW}[+] Installing Python modules...${RESET}"

PY_MODULES=(
  python-nmap
)

for module in "${PY_MODULES[@]}"; do
  echo -e "${CYAN}  [~] Installing: $module${RESET}"
  pip3 install "$module" --break-system-packages > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}  [✓] $module ready.${RESET}"
  else
    echo -e "${RED}  [!] Failed: $module${RESET}"
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
