#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
LOG_FILE="$LOG_DIR/toolkit-$(date +%Y-%m-%d).log"

log_info() {
    local msg
    msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${GREEN}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg
    msg="[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${YELLOW}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg
    msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${RED}${msg}${RESET}" >&2
    echo "$msg" >> "$LOG_FILE"
}

log_section() {
    local msg="$1"
    echo -e "\n${BOLD}${CYAN}========== ${msg} ==========${RESET}\n"
    echo "========== ${msg} ==========" >> "$LOG_FILE"
}

die() {
    log_error "$1"
    exit "${2:-1}"
}

require_command() {
    command -v "$1" &>/dev/null || die "Required command '$1' not found."
}

confirm() {
    local prompt="${1:-Are you sure?}"
    read -rp "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

require_root() {
    [[ "$EUID" -eq 0 ]] || die "This script must be run as root."
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
