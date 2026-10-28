#!/usr/bin/env bash
# network-check.sh - Basic network diagnostics for a host
# Usage: ./network-check.sh <hostname-or-ip> [port]
# Exit codes: 0 = all checks passed, 1 = a network check failed, 2 = invalid input

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/network-check.log"
mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [network-check] $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]"
    echo "Example: $0 google.com 443"
}

# --- Validate arguments ---
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Error: wrong number of arguments." >&2
    usage
    log "Invalid input: wrong number of arguments ($#)"
    exit 2
fi

HOST="$1"
PORT="${2:-}"

# Hostnames/IPs may only contain letters, digits, dots and hyphens,
# must not start with a hyphen and must be at most 253 characters
if [[ -z "$HOST" || ${#HOST} -gt 253 || ! "$HOST" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
    echo "Error: invalid hostname or IP address '$HOST'." >&2
    usage
    log "Invalid input: bad host '$HOST'"
    exit 2
fi

if [[ -n "$PORT" ]]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be a number, got '$PORT'." >&2
        usage
        log "Invalid input: non-numeric port '$PORT'"
        exit 2
    fi
    PORT=$((10#$PORT))
    if (( PORT < 1 || PORT > 65535 )); then
        echo "Error: port must be between 1 and 65535, got '$PORT'." >&2
        usage
        log "Invalid input: port out of range '$PORT'"
        exit 2
    fi
fi

log "Starting network check for host '$HOST'${PORT:+ port $PORT}"
FAILED=0

# --- Resolve the host ---
echo "===== Network Check: $HOST ====="
RESOLVED_IP=$(getent hosts "$HOST" | awk '{print $1; exit}')

if [[ -z "$RESOLVED_IP" ]]; then
    echo "Resolve:      FAILED (could not resolve '$HOST')"
    log "Resolve failed for '$HOST'"
    exit 1
fi
echo "Resolved IP:  $RESOLVED_IP"
log "Resolved '$HOST' to $RESOLVED_IP"

# --- Connectivity (ping) ---
if ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
    echo "Ping:         OK"
    log "Ping to '$HOST' succeeded"
else
    echo "Ping:         FAILED (no reply)"
    log "Ping to '$HOST' failed"
    FAILED=1
fi

# --- TCP port check (optional) ---
if [[ -n "$PORT" ]]; then
    if nc -z -w 3 "$HOST" "$PORT" >/dev/null 2>&1; then
        echo "TCP port $PORT: OPEN"
        log "TCP port $PORT on '$HOST' is open"
    else
        echo "TCP port $PORT: CLOSED or unreachable"
        log "TCP port $PORT on '$HOST' is closed or unreachable"
        FAILED=1
    fi
fi

# --- Network interfaces ---
echo
echo "Network interfaces:"
if command -v ip >/dev/null 2>&1; then
    ip -brief address
else
    echo "  ('ip' command not available)"
fi
echo "================================"

if (( FAILED )); then
    log "Network check for '$HOST' finished with failures"
    exit 1
fi

log "Network check for '$HOST' finished successfully"
exit 0
