#!/bin/bash
# backup-manager.sh — Backup tool with retention policy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

BACKUP_ROOT="${HOME}/backups"
RETENTION_DAYS=7

usage() {
    echo -e "${BOLD}Usage:${RESET} $0 <source_directory> [backup_root]"
    echo -e "  source_directory  — directory to back up"
    echo -e "  backup_root       — where to store backups (default: ~/backups)"
    exit 1
}

create_backup() {
    local source_dir="$1"
    local target_dir="${2:-$BACKUP_ROOT}"

    [[ -d "$source_dir" ]] || die "Source directory '$source_dir' does not exist."

    mkdir -p "$target_dir"

    local source_name
    source_name=$(basename "$source_dir")
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${target_dir}/${source_name}_${timestamp}.tar.gz"

    log_info "Starting backup: $source_dir → $backup_file"

    tar -czf "$backup_file" -C "$(dirname "$source_dir")" "$source_name" 2>/dev/null \
        || die "Backup failed for $source_dir"

    local size
    size=$(du -sh "$backup_file" | cut -f1)
    log_info "Backup complete. Size: $size → $backup_file"
}

apply_retention() {
    local target_dir="${1:-$BACKUP_ROOT}"
    log_info "Applying retention policy: removing backups older than ${RETENTION_DAYS} days"

    local count=0
    while IFS= read -r old_backup; do
        rm -f "$old_backup"
        log_warn "Deleted old backup: $old_backup"
        ((count++))
    done < <(find "$target_dir" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" 2>/dev/null)

    log_info "Retention cleanup complete. Removed $count old backup(s)."
}

list_backups() {
    local target_dir="${1:-$BACKUP_ROOT}"
    log_section "Existing Backups in $target_dir"

    if [[ ! -d "$target_dir" ]] || [[ -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
        log_warn "No backups found in $target_dir"
        return
    fi

    ls -lh "$target_dir"/*.tar.gz 2>/dev/null || log_warn "No .tar.gz backups found"
}

main() {
    [[ $# -lt 1 ]] && usage

    local source="$1"
    local destination="${2:-$BACKUP_ROOT}"

    log_section "Backup Manager"
    create_backup "$source" "$destination"
    apply_retention "$destination"
    list_backups "$destination"
}

main "$@"
