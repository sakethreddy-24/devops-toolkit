#!/bin/bash
# =====================================================
# common.sh — Shared library for devops-toolkit
# ============================================================

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Logging setup ---
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
LOG_FILE="$LOG_DIR/toolkit-$(date +%Y-%m-%d).log"

# --- Logging Functions ---
log_info() {
    local msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${GREEN}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${YELLOW}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${RED}${msg}${RESET}" >&2
    echo "$msg" >> "$LOG_FILE"
}

log_section() {
    local msg="$1"
    echo -e "\n${BOLD}${CYAN}========== ${msg} ==========${RESET}\n"
    echo "========== ${msg} ==========" >> "$LOG_FILE"
}

# --- Error Handling ---
die() {
    log_error "$1"
    exit "${2:-1}"
}

# --- Dependency checker ---
require_command() {
    command -v "$1" &>/dev/null || die "Required command '$1' not found. Please install it."
}

# --- Confirm prompt ---
confirm() {
    local prompt="${1:-Are you sure?}"
    read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${RESET}")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

# --- Root check ---
require_root() {
    [[ "$EUID" -eq 0 ]] || die "This script must be run as root."
}

# --- OS detection ---
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
