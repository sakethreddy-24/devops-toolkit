#!/bin/bash
# user-manager.sh — Batch user management with SSH key setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
    echo -e "${BOLD}Usage:${RESET} $0 <command> [options]"
    echo ""
    echo -e "${BOLD}Commands:${RESET}"
    echo -e "  create username group   -- Create a user with SSH key"
    echo -e "  delete username         -- Delete a user and home directory"
    echo -e "  list                    -- List all non-system users"
    echo -e "  info username           -- Show user details"
    echo -e "  batch csv-file          -- Bulk create users from CSV"
    exit 1
}

create_user() {
    local username="$1"
    local group="${2:-developers}"

    require_root
    [[ -z "$username" ]] && die "Username required"
    id "$username" &>/dev/null && die "User $username already exists"

    getent group "$group" &>/dev/null || groupadd "$group"

    useradd -m -s /bin/bash -G "$group" "$username" \
        || die "Failed to create user $username"

    local ssh_dir="/home/$username/.ssh"
    mkdir -p "$ssh_dir"

    ssh-keygen -t ed25519 -f "${ssh_dir}/id_ed25519" -N "" -C "${username}@$(hostname)" \
        || die "Failed to generate SSH key for $username"

    cp "${ssh_dir}/id_ed25519.pub" "${ssh_dir}/authorized_keys"

    chown -R "$username:$username" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "${ssh_dir}/authorized_keys"
    chmod 600 "${ssh_dir}/id_ed25519"

    log_info "User $username created successfully"
    log_info "Group: $group"
    log_info "Home: /home/$username"
    log_warn "Distribute private key securely"
}

delete_user() {
    local username="$1"
    require_root
    [[ -z "$username" ]] && die "Username required"
    id "$username" &>/dev/null || die "User $username does not exist"

    confirm "Delete user $username and their home directory?" || exit 0

    userdel -r "$username" 2>/dev/null
    log_info "User $username deleted"
}

list_users() {
    log_section "System Users UID 1000 and above"
    echo -e "${BOLD}$(printf '%-15s %-6s %-20s %s\n' 'USERNAME' 'UID' 'HOME' 'SHELL')${RESET}"
    printf '%.0s-' {1..60}
    echo ""

    while IFS=: read -r user _ uid _ _ home shell; do
        if [[ $uid -ge 1000 && $uid -lt 65534 ]]; then
            echo "$(printf '%-15s %-6s %-20s %s\n' "$user" "$uid" "$home" "$shell")"
        fi
    done < /etc/passwd
}

user_info() {
    local username="$1"
    [[ -z "$username" ]] && die "Username required"
    id "$username" &>/dev/null || die "User $username does not exist"

    log_section "User Info: $username"
    id "$username"
    echo -e "${BOLD}Shell:${RESET} $(getent passwd "$username" | cut -d: -f7)"
    echo -e "${BOLD}Groups:${RESET} $(groups "$username")"

    local ssh_key="/home/$username/.ssh/id_ed25519.pub"
    if [[ -f "$ssh_key" ]]; then
        echo -e "${BOLD}SSH Key:${RESET} $(cat "$ssh_key")"
    else
        log_warn "No SSH key found for $username"
    fi
}

batch_create() {
    local csv_file="$1"
    require_root
    [[ -f "$csv_file" ]] || die "CSV file not found: $csv_file"

    log_section "Batch User Creation from $csv_file"
    local success=0
    local failed=0

    while IFS=, read -r username group; do
        [[ -z "$username" || "$username" == \#* ]] && continue
        username=$(echo "$username" | tr -d '[:space:]')
        group=$(echo "$group" | tr -d '[:space:]')

        if create_user "$username" "${group:-developers}"; then
            ((success++))
        else
            log_error "Failed to create user: $username"
            ((failed++))
        fi
    done < "$csv_file"

    log_info "Batch complete. Created: $success | Failed: $failed"
}

main() {
    [[ $# -lt 1 ]] && usage
    local command="$1"
    shift

    case "$command" in
        create) create_user "$@" ;;
        delete) delete_user "$@" ;;
        list)   list_users ;;
        info)   user_info "$@" ;;
        batch)  batch_create "$@" ;;
        *)      usage ;;
    esac
}

main "$@"
