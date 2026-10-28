#!/usr/bin/env bash
# disk-check.sh - Check disk usage against a threshold
# Usage: ./disk-check.sh <threshold> [path]
# Exit codes: 0 = below threshold, 1 = at/above threshold or check failed, 2 = invalid input

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/disk-check.log"
mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [disk-check] $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <threshold 1-100> [path]"
    echo "Example: $0 80 /"
}

# --- Validate arguments ---
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Error: wrong number of arguments." >&2
    usage
    log "Invalid input: wrong number of arguments ($#)"
    exit 2
fi

THRESHOLD="$1"
TARGET_PATH="${2:-/}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be a whole number, got '$THRESHOLD'." >&2
    usage
    log "Invalid input: non-numeric threshold '$THRESHOLD'"
    exit 2
fi

# 10# forces base 10, so values like 08 are not read as octal
THRESHOLD=$((10#$THRESHOLD))

if (( THRESHOLD < 1 || THRESHOLD > 100 )); then
    echo "Error: threshold must be between 1 and 100, got '$THRESHOLD'." >&2
    usage
    log "Invalid input: threshold out of range '$THRESHOLD'"
    exit 2
fi

if [[ ! -e "$TARGET_PATH" ]]; then
    echo "Error: path '$TARGET_PATH' does not exist." >&2
    log "Invalid input: path does not exist '$TARGET_PATH'"
    exit 2
fi

# --- Check disk usage ---
log "Checking disk usage for '$TARGET_PATH' with threshold ${THRESHOLD}%"

USAGE=$(df -P "$TARGET_PATH" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')

if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: could not read disk usage for '$TARGET_PATH'." >&2
    log "Failed to read disk usage for '$TARGET_PATH'"
    exit 1
fi

echo "Disk usage for $TARGET_PATH: ${USAGE}% (threshold: ${THRESHOLD}%)"

if (( USAGE >= THRESHOLD )); then
    echo "WARNING: disk usage has reached or exceeded the threshold."
    log "WARNING: usage ${USAGE}% >= threshold ${THRESHOLD}% for '$TARGET_PATH'"
    exit 1
fi

echo "OK: disk usage is below the threshold."
log "OK: usage ${USAGE}% < threshold ${THRESHOLD}% for '$TARGET_PATH'"
exit 0
