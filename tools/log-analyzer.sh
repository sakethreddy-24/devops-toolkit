#!/bin/bash
# log-analyzer.sh - Parse logs, find errors, generate summary report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

usage() {
echo -e "${BOLD}Usage:${RESET} $0 <logfile> [options]"
echo -e " -e Show only errors"
echo -e " -w SHow only warnings"
echo -e " -t Show top 10 most frequent error messages"
echo -e " -s Summary only"
exit 1
}

validate_file() {
local file="$1"
[[ -z "$file" ]] && usage
[[ -f "$file" ]] || die "Log file not found: $file"
[[ -r "$file" ]] || die "Log file not readable: $file"
}

count_occurences() {
local file="$1"
local pattern="$2"
grep -ci "$pattern" "$file" 2>/dev/null || echo 0
}

show_summary() {
    local file="$1"
    local total lines errors warnings criticals

    lines=$(wc -l < "$file")
    errors=$(count_occurrences "$file" "\[error\]\|error:\| ERROR ")
    warnings=$(count_occurrences "$file" "\[warn\]\|warning:\| WARN ")
    criticals=$(count_occurrences "$file" "\[critical\]\|critical:\| CRITICAL ")

    log_section "Log Analysis Summary"
    echo -e "${BOLD}File:${RESET}     $file"
    echo -e "${BOLD}Size:${RESET}     $(du -sh "$file" | cut -f1)"
    echo -e "${BOLD}Lines:${RESET}    $lines"
    echo ""
    echo -e "${RED}${BOLD}Errors:${RESET}    $errors"
    echo -e "${YELLOW}${BOLD}Warnings:${RESET}  $warnings"
    echo -e "${RED}${BOLD}Critical:${RESET}  $criticals"
    echo ""

    if [[ $errors -eq 0 && $criticals -eq 0 ]]; then
        log_info "No errors or critical issues found"
    elif [[ $criticals -gt 0 ]]; then
        log_error "Critical issues detected — immediate attention required"
    else
        log_warn "Errors found — review recommended"
    fi
}

show_errors() {
    local file="$1"
    log_section "Error Lines"
    grep -n --color=always -i "error\|critical\|fatal" "$file" | head -50 \
        || log_info "No error lines found"
}

show_warnings() {
    local file="$1"
    log_section "Warning Lines"
    grep -n --color=always -i "warn" "$file" | head -50 \
        || log_info "No warning lines found"
}

show_top_errors() {
    local file="$1"
    log_section "Top 10 Most Frequent Error Patterns"
    grep -i "error\|critical\|fatal" "$file" \
        | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//g' \
        | sed 's/[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}//g' \
        | sort | uniq -c | sort -rn | head -10 \
        || log_info "No error patterns found"
}

show_timeline() {
    local file="$1"
    log_section "Error Timeline (errors per hour)"
    grep -i "error\|critical" "$file" \
        | grep -oP '\d{4}-\d{2}-\d{2} \d{2}' \
        | sort | uniq -c \
        | awk '{printf "  %s:00  —  %s errors\n", $2, $1}' \
        || log_info "Could not extract timeline (timestamp format may differ)"
}

main() {
    local logfile="$1"
    shift
    validate_file "$logfile"

    local show_err=false show_warn=false show_top=false summary_only=false

    while getopts "ewts" opt; do
        case $opt in
            e) show_err=true ;;
            w) show_warn=true ;;
            t) show_top=true ;;
            s) summary_only=true ;;
            *) usage ;;
        esac
    done

    show_summary "$logfile"

    if [[ "$summary_only" == true ]]; then
        exit 0
    fi

    $show_err && show_errors "$logfile"
    $show_warn && show_warnings "$logfile"
    $show_top && show_top_errors "$logfile"

    if ! $show_err && ! $show_warn && ! $show_top; then
        show_errors "$logfile"
        show_top_errors "$logfile"
        show_timeline "$logfile"
    fi
}

main "$@"
