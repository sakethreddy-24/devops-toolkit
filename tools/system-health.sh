#!/bin/bash
# system-health.sh - System health report tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# --- Thresholds ---
CPU_WARN=70
CPU_CRIT=90
MEM_WARN=80
MEM_CRIT=95
DISK_WARN=80
DISK_CRIT=95

check_cpu() {
    log_section "CPU Usage"
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
    local cpu_used=$((100 - cpu_idle))

    if [[ $cpu_used -ge $CPU_CRIT ]]; then
        log_error "CPU usage: ${cpu_used}% — CRITICAL"
    elif [[ $cpu_used -ge $CPU_WARN ]]; then
        log_warn "CPU usage: ${cpu_used}% — WARNING"
    else
        log_info "CPU usage: ${cpu_used}% — OK"
    fi

    echo -e "${BOLD}Load Average:${RESET} $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo -e "${BOLD}CPU Cores:${RESET} $(nproc)"
}

check_memory() {
    log_section "Memory Usage"
    local total
    local used
    local mem_pct
    total=$(free -m | awk '/^Mem:/{print $2}')
    used=$(free -m | awk '/^Mem:/{print $3}')
    mem_pct=$(( used * 100 / total ))

    if [[ $mem_pct -ge $MEM_CRIT ]]; then
        log_error "Memory: ${used}MB / ${total}MB (${mem_pct}%) — CRITICAL"
    elif [[ $mem_pct -ge $MEM_WARN ]]; then
        log_warn "Memory: ${used}MB / ${total}MB (${mem_pct}%) — WARNING"
    else
        log_info "Memory: ${used}MB / ${total}MB (${mem_pct}%) — OK"
    fi

    echo -e "${BOLD}Swap:${RESET} $(free -m | awk '/^Swap:/{print $3}')MB used"
}

check_disk() {
    log_section "Disk Usage"
    while IFS= read -r line; do
        local usage mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')

        if [[ $usage -ge $DISK_CRIT ]]; then
            log_error "Disk $mount: ${usage}% — CRITICAL"
        elif [[ $usage -ge $DISK_WARN ]]; then
            log_warn "Disk $mount: ${usage}% — WARNING"
        else
            log_info "Disk $mount: ${usage}% — OK"
        fi
    done < <(df -h | grep '^/dev/' | grep -v tmpfs)
}

check_processes() {
    log_section "Top Processes by CPU"
    ps aux --sort=-%cpu | head -6 | awk 'NR==1{print} NR>1{printf "%-10s %-6s %-6s %s\n", $1, $2, $3, $11}'
}


check_network() {
    log_section "Network Interfaces"
    ip -brief addr show | grep -v '^lo'
}

generate_report() {
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║       SYSTEM HEALTH REPORT             ║"
    echo "║       $(date '+%Y-%m-%d %H:%M:%S')        ║"
    echo "║       Host: $(hostname)                ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${RESET}"

    check_cpu
    check_memory
    check_disk
    check_processes
    check_network

    log_section "Report Complete"
    log_info "Full log saved to: $LOG_FILE"
}

generate_report
