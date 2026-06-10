#!/bin/bash
# port-scanner.sh — Check open ports and listening services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

TIMEOUT=2

usage() {
    echo -e "${BOLD}Usage:${RESET} $0 [host] [options]"
    echo -e "  host          Target host (default: localhost)"
    echo -e "  -p <ports>    Comma-separated ports to scan (default: common ports)"
    echo -e "  -l            Show locally listening services only"
    echo -e "  -a            Scan all common ports (1-1024)"
    exit 1
}

COMMON_PORTS=(21 22 23 25 53 80 443 3000 3306 5432 5672 6379 8080 8443 8888 9090 9200 27017)

scan_port() {
    local host="$1"
    local port="$2"
    if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        return 0
    fi
    return 1
}

get_service_name() {
    local port="$1"
    case $port in
        21) echo "FTP" ;; 22) echo "SSH" ;; 23) echo "Telnet" ;;
        25) echo "SMTP" ;; 53) echo "DNS" ;; 80) echo "HTTP" ;;
        443) echo "HTTPS" ;; 3000) echo "Node/React" ;; 3306) echo "MySQL" ;;
        5432) echo "PostgreSQL" ;; 5672) echo "RabbitMQ" ;; 6379) echo "Redis" ;;
        8080) echo "HTTP-Alt" ;; 8443) echo "HTTPS-Alt" ;; 8888) echo "Jupyter" ;;
        9090) echo "Prometheus" ;; 9200) echo "Elasticsearch" ;; 27017) echo "MongoDB" ;;
        *) echo "Unknown" ;;
    esac
}

scan_host() {
    local host="$1"
    shift
    local ports=("$@")

    log_section "Port Scan: $host"
    echo -e "${BOLD}$(printf '%-8s %-15s %-12s %s\n' 'PORT' 'SERVICE' 'STATUS' 'NOTE')${RESET}"
    echo "$(printf '%.0s─' {1..50})"

    local open_count=0
    for port in "${ports[@]}"; do
        local service status color note=""
        service=$(get_service_name "$port")

        if scan_port "$host" "$port"; then
            status="OPEN"
            color="$GREEN"
            ((open_count++))
            [[ "$port" == "23" ]] && note="⚠ Insecure protocol"
            [[ "$port" == "21" ]] && note="⚠ Use SFTP instead"
        else
            status="CLOSED"
            color="$RED"
        fi

        echo -e "${color}$(printf '%-8s %-15s %-12s %s\n' "$port" "$service" "$status" "$note")${RESET}"
    done

    echo ""
    log_info "Scan complete. $open_count open port(s) found on $host"
}

show_listening_services() {
    log_section "Locally Listening Services"
    echo -e "${BOLD}$(printf '%-10s %-10s %s\n' 'PROTO' 'PORT' 'ADDRESS')${RESET}"
    echo "$(printf '%.0s─' {1..40})"

    ss -tlnp 2>/dev/null | tail -n +2 | while read -r line; do
        local port addr
        addr=$(echo "$line" | awk '{print $4}')
        port=$(echo "$addr" | rev | cut -d: -f1 | rev)
        echo -e "${GREEN}$(printf '%-10s %-10 %s\n' 'TCP' "$port" "$addr")${RESET}"
    done
}

main() {
    local host="localhost"
    local custom_ports=()
    local list_only=false
    local scan_all=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l) list_only=true ;;
            -a) scan_all=true ;;
            -p) IFS=',' read -ra custom_ports <<< "$2"; shift ;;
            -h|--help) usage ;;
            *) host="$1" ;;
        esac
        shift
    done

    if [[ "$list_only" == true ]]; then
        show_listening_services
        exit 0
    fi

    local ports_to_scan
    if [[ ${#custom_ports[@]} -gt 0 ]]; then
        ports_to_scan=("${custom_ports[@]}")
    elif [[ "$scan_all" == true ]]; then
        map file -t ports_to_scan <<($(seq 1 1024))
    else
        ports_to_scan=("${COMMON_PORTS[@]}")
    fi

    scan_host "$host" "${ports_to_scan[@]}"
    show_listening_services
}

main "$@"
