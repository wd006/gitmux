#!/usr/bin/env bash

# terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# idempotency markers
MARKER_START="# === BEGIN GITMUX AUTO-GENERATED ==="
MARKER_END="# === END GITMUX AUTO-GENERATED ==="

# safely remove generated blocks (cross-platform awk)
remove_marker_block() {
    local file=$1
    if [[ -f "$file" ]]; then
        awk "/$MARKER_START/{flag=1; next} /$MARKER_END/{flag=0; next} !flag" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# handle cleanup routine
if [[ "$1" == "--clean" ]]; then
    echo -e "${YELLOW}[*] Cleaning up GitMux configurations...${NC}"
    remove_marker_block "$HOME/.gitconfig"
    remove_marker_block "$HOME/.ssh/config"
    echo -e "${GREEN}[+] Cleanup complete. Global settings restored.${NC}"
    exit 0
fi

# ascii art header
echo -e "${BLUE}"
cat << "EOF"
   _______ __  __  ___          
  / ____(_) /_/  |/  /_  ___  __
 / / __/ / __/ /|_/ / / / / |/_/
/ /_/ / / /_/ /  / / /_/ />  <  
\____/_/\__/_/  /_/\__,_/_/|_|  
                                
EOF
echo -e "${NC}"
echo -e "${CYAN}=== GitMux: Multi-Profile Identity & Security Manager ===${NC}\n"

# dependency check (gpg)
HAS_GPG=0
if command -v gpg >/dev/null 2>&1; then
    HAS_GPG=1
else
    echo -e "${YELLOW}[!] Warning: GnuPG is not installed. GPG Commit Signing feature will be disabled.${NC}"
    echo -e "    To enable it, install GPG (e.g., 'brew install gnupg' or 'apt install gnupg').\n"
fi

read -p "[?] How many Git profiles do you want to configure? (e.g., 2): " PROFILE_COUNT

if ! [[ "$PROFILE_COUNT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[-] Error: Please enter a valid number.${NC}"
    exit 1
fi

# enforce secure permissions for base directories
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.gitconfig" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

GITCONFIG_BLOCK=""
SSHCONFIG_BLOCK=""
declare -a GENERATED_SSH_KEYS=()
declare -a GENERATED_GPG_KEYS=()

for (( i=1; i<=PROFILE_COUNT; i++ ))
do
    echo -e "\n${YELLOW}--- Configuring Profile $i ---${NC}"
    
    read -p "    Profile Name (e.g., work): " PROF_NAME
    read -p "    Git Username (e.g., John Doe): " PROF_GIT_NAME
    read -p "    Git Email (e.g., john@company.com): " PROF_GIT_EMAIL
    read -p "    Base Directory (e.g., ~/Projects/Work): " PROF_DIR
    
    # parse tilde to home dir and ensure trailing slash
    PROF_DIR="${PROF_DIR/#\~/$HOME}"
    [[ "${PROF_DIR}" != */ ]] && PROF_DIR="${PROF_DIR}/"
    mkdir -p "$PROF_DIR"
    
    # ssh key management
    DEFAULT_SSH_KEY="$HOME/.ssh/id_ed25519_$PROF_NAME"
    read -p "    SSH Key Path [$DEFAULT_SSH_KEY]: " INPUT_SSH_KEY
    PROF_SSH_KEY="${INPUT_SSH_KEY:-$DEFAULT_SSH_KEY}"
    PROF_SSH_KEY="${PROF_SSH_KEY/#\~/$HOME}"

    if [[ ! -f "$PROF_SSH_KEY" ]]; then
        read -p "    [?] SSH key not found. Generate a new ED25519 key? (y/n): " CREATE_KEY
        if [[ "$CREATE_KEY" =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -C "$PROF_GIT_EMAIL" -f "$PROF_SSH_KEY" -q -N ""
            echo -e "    ${GREEN}[+] New SSH key generated.${NC}"
            GENERATED_SSH_KEYS+=("${PROF_NAME}|${PROF_GIT_NAME}|${PROF_SSH_KEY}.pub")
        else
            echo -e "    ${RED}[-] Key generation skipped.${NC}"
        fi
    else
        echo -e "    ${GREEN}[+] Existing SSH key found.${NC}"
        GENERATED_SSH_KEYS+=("${PROF_NAME}|${PROF_GIT_NAME}|${PROF_SSH_KEY}.pub")
    fi

    # ssh routing method selection
    echo -e "\n    ${BLUE}SSH Routing Method:${NC}"
    echo "    1) Transparent (core.sshCommand) - Recommended"
    echo "    2) Classic (SSH Alias) - Requires git@github-$PROF_NAME:..."
    read -p "    Selection (1/2): " SSH_METHOD

    # build sub-config file payload
    SUB_CONFIG_FILE="$HOME/.gitconfig-$PROF_NAME"
    cat > "$SUB_CONFIG_FILE" << EOF
[user]
    name = $PROF_GIT_NAME
    email = $PROF_GIT_EMAIL
EOF

    if [[ "$SSH_METHOD" == "1" ]]; then
        cat >> "$SUB_CONFIG_FILE" << EOF
[core]
    sshCommand = "ssh -i $PROF_SSH_KEY"
EOF
    elif [[ "$SSH_METHOD" == "2" ]]; then
        SSHCONFIG_BLOCK+="$(cat <<EOF

Host github-$PROF_NAME
    HostName github.com
    User git
    IdentityFile $PROF_SSH_KEY
EOF
)"
    fi

    # gpg management (verified badge setup)
    if [[ $HAS_GPG -eq 1 ]]; then
        echo -e "\n    ${BLUE}GPG Commit Signing (Verified Badge)${NC}"
        read -p "    [?] Enable GPG signing for this profile? (y/n): " ENABLE_GPG
        
        if [[ "$ENABLE_GPG" =~ ^[Yy]$ ]]; then
            EXISTING_CHECK=$(gpg --list-secret-keys "$PROF_GIT_EMAIL" 2>/dev/null)
            GPG_KEY_ID=""

            if [[ -n "$EXISTING_CHECK" ]]; then
                GPG_KEY_ID=$(gpg --list-secret-keys --with-colons "$PROF_GIT_EMAIL" 2>/dev/null | awk -F: '/^fpr:/ {print $10}' | head -n 1)
                echo -e "    ${GREEN}[+] Existing GPG key found for $PROF_GIT_EMAIL (ID: $GPG_KEY_ID)${NC}"
                GENERATED_GPG_KEYS+=("${PROF_NAME}|${PROF_GIT_NAME}|${GPG_KEY_ID}")
            else
                read -p "    [?] No GPG key found. Generate one now? (y/n): " GEN_GPG
                if [[ "$GEN_GPG" =~ ^[Yy]$ ]]; then
                    read -s -p "    [!] Enter a passphrase for GPG (leave blank for NO password): " GPG_PASS
                    echo ""
                    echo -e "    ${YELLOW}[*] Generating GPG Key (This may take a few seconds)...${NC}"
                    
                    BATCH_FILE=$(mktemp)
                    cat <<GPGEOF > "$BATCH_FILE"
Key-Type: RSA
Key-Length: 4096
Name-Real: $PROF_GIT_NAME
Name-Email: $PROF_GIT_EMAIL
Expire-Date: 0
GPGEOF
                    if [[ -z "$GPG_PASS" ]]; then
                        echo "%no-protection" >> "$BATCH_FILE"
                    else
                        echo "Passphrase: $GPG_PASS" >> "$BATCH_FILE"
                    fi
                    echo "%commit" >> "$BATCH_FILE"

                    gpg --batch --generate-key "$BATCH_FILE" 2>/dev/null
                    rm -f "$BATCH_FILE"

                    GPG_KEY_ID=$(gpg --list-secret-keys --with-colons "$PROF_GIT_EMAIL" 2>/dev/null | awk -F: '/^fpr:/ {print $10}' | head -n 1)
                    echo -e "    ${GREEN}[+] GPG Key successfully generated (ID: $GPG_KEY_ID)${NC}"
                    GENERATED_GPG_KEYS+=("${PROF_NAME}|${PROF_GIT_NAME}|${GPG_KEY_ID}")
                fi
            fi

            if [[ -n "$GPG_KEY_ID" ]]; then
                cat >> "$SUB_CONFIG_FILE" << EOF
[commit]
    gpgsign = true
[user]
    signingkey = $GPG_KEY_ID
EOF
                echo -e "    ${GREEN}[+] GPG signing configured for $PROF_NAME.${NC}"
            fi
        fi
    fi

    # append routing rules to global git config block
    GITCONFIG_BLOCK+="$(cat <<EOF

[includeIf "gitdir:$PROF_DIR"]
    path = $SUB_CONFIG_FILE
EOF
)"

    echo -e "    ${GREEN}[+] Profile '$PROF_NAME' configured successfully.${NC}"
done

# inject configuration blocks into system files
echo -e "\n${YELLOW}[*] Injecting configurations into system files...${NC}"

remove_marker_block "$HOME/.gitconfig"
remove_marker_block "$HOME/.ssh/config"

if [[ -n "$GITCONFIG_BLOCK" ]]; then
    echo "$MARKER_START" >> "$HOME/.gitconfig"
    echo "$GITCONFIG_BLOCK" >> "$HOME/.gitconfig"
    echo "$MARKER_END" >> "$HOME/.gitconfig"
fi

if [[ -n "$SSHCONFIG_BLOCK" ]]; then
    echo "$MARKER_START" >> "$HOME/.ssh/config"
    echo "$SSHCONFIG_BLOCK" >> "$HOME/.ssh/config"
    echo "$MARKER_END" >> "$HOME/.ssh/config"
fi

echo -e "${GREEN}[+] Configurations applied successfully!${NC}"

# ==========================================
# DASHBOARD & KEY EXPORT LOGIC
# ==========================================

SUMMARY_FILE="$PWD/gitmux_summary.log"
> "$SUMMARY_FILE" # clear or initialize the export file

TOTAL_SSH_KEYS=${#GENERATED_SSH_KEYS[@]}
TOTAL_GPG_KEYS=${#GENERATED_GPG_KEYS[@]}
TOTAL_STEPS=$(( TOTAL_SSH_KEYS + TOTAL_GPG_KEYS ))
CURRENT_STEP=1

if [ $TOTAL_STEPS -gt 0 ]; then
    
    # write summary header to log file
    echo "=== GitMux: Generated Keys Summary ===" >> "$SUMMARY_FILE"
    echo "DO NOT share your private keys. Only add these PUBLIC keys to GitHub/GitLab." >> "$SUMMARY_FILE"
    echo -e "------------------------------------------\n" >> "$SUMMARY_FILE"

    # append ssh keys to log
    for entry in "${GENERATED_SSH_KEYS[@]}"; do
        IFS='|' read -r p_name p_gitname p_pubkey <<< "$entry"
        if [[ -f "$p_pubkey" ]]; then
            echo "[SSH KEY] Profile: $p_name ($p_gitname)" >> "$SUMMARY_FILE"
            cat "$p_pubkey" >> "$SUMMARY_FILE"
            echo -e "\n" >> "$SUMMARY_FILE"
        fi
    done

    # append gpg keys to log
    for entry in "${GENERATED_GPG_KEYS[@]}"; do
        IFS='|' read -r p_name p_gitname p_fingerprint <<< "$entry"
        echo "[GPG KEY] Profile: $p_name ($p_gitname) - ID: $p_fingerprint" >> "$SUMMARY_FILE"
        gpg --armor --export "$p_fingerprint" >> "$SUMMARY_FILE"
        echo -e "\n" >> "$SUMMARY_FILE"
    done

    # interactive terminal dashboard
    SKIP_UI=0
    
    echo -e "\n${CYAN}=========================================================================${NC}"
    echo -e "${YELLOW}  ACTION REQUIRED: Add your Public Keys to your Git provider${NC}"
    echo -e "${CYAN}=========================================================================${NC}"

    # render ssh keys ui
    for entry in "${GENERATED_SSH_KEYS[@]}"; do
        if [[ $SKIP_UI -eq 1 ]]; then break; fi
        
        IFS='|' read -r p_name p_gitname p_pubkey <<< "$entry"
        if [[ -f "$p_pubkey" ]]; then
            PUBKEY_CONTENT=$(cat "$p_pubkey")
            
            echo -e "\n${CYAN}┌───────────────────────────────────────────────────────────────────────${NC}"
            echo -e "${CYAN}│ ${YELLOW}🔑 SSH KEY | PROFILE: ${GREEN}${p_name} ${NC}(${p_gitname})  ${CYAN}[Step ${CURRENT_STEP}/${TOTAL_STEPS}]${NC}"
            echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────${NC}"
            echo -e "${BLUE}Instructions:${NC}"
            echo -e "  1. Log into the correct GitHub account for ${GREEN}'${p_name}'${NC}."
            echo -e "  2. Go to: ${CYAN}https://github.com/settings/ssh/new${NC}"
            echo -e "  3. Copy the entire text below and paste it into the 'Key' field:"
            echo -e "\n${NC}${PUBKEY_CONTENT}\n"

            if [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; then
                read -p "$(echo -e ${YELLOW}"Press [ENTER] for next key, or [q] to skip terminal output: "${NC})" USER_CHOICE
                if [[ "$USER_CHOICE" == "q" || "$USER_CHOICE" == "Q" ]]; then
                    SKIP_UI=1
                fi
            fi
            ((CURRENT_STEP++))
        fi
    done

    # render gpg keys ui
    for entry in "${GENERATED_GPG_KEYS[@]}"; do
        if [[ $SKIP_UI -eq 1 ]]; then break; fi

        IFS='|' read -r p_name p_gitname p_fingerprint <<< "$entry"
        GPG_ARMOR=$(gpg --armor --export "$p_fingerprint")
        
        echo -e "\n${CYAN}┌───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}│ ${YELLOW}🛡️  GPG KEY | PROFILE: ${GREEN}${p_name} ${NC}(${p_gitname})  ${CYAN}[Step ${CURRENT_STEP}/${TOTAL_STEPS}]${NC}"
        echo -e "${CYAN}└───────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${BLUE}Instructions:${NC}"
        echo -e "  1. Log into the correct GitHub account for ${GREEN}'${p_name}'${NC}."
        echo -e "  2. Go to: ${CYAN}https://github.com/settings/gpg/new${NC}"
        echo -e "  3. Copy the entire text below to get the 'Verified' badge on your commits:"
        echo -e "\n${NC}${GPG_ARMOR}\n"

        if [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; then
            read -p "$(echo -e ${YELLOW}"Press [ENTER] for next key, or [q] to skip terminal output: "${NC})" USER_CHOICE
            if [[ "$USER_CHOICE" == "q" || "$USER_CHOICE" == "Q" ]]; then
                SKIP_UI=1
            fi
        fi
        ((CURRENT_STEP++))
    done

    # finalize and display export path
    echo -e "\n${CYAN}=========================================================================${NC}"
    echo -e "${GREEN}[✓] Setup Complete. Happy coding!${NC}"
    echo -e "${BLUE}[i] In case you skipped or cleared the terminal, all keys are saved to:${NC}"
    echo -e "    ${YELLOW}${SUMMARY_FILE}${NC}"
    echo -e "    ${NC}You can open this log file anytime to copy your keys safely.\n"
fi