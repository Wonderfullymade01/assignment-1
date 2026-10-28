#!/usr/bin/env bash
# system-info.sh - Display basic system information

set -u

# Find the folder this script lives in, so logs always go to ./logs
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/system-info.log"
mkdir -p "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [system-info] $1" >> "$LOG_FILE"
}

log "Started system information check"

echo "===== System Information ====="
echo "Hostname:          $(hostname)"
echo "Current user:      $(whoami)"
echo "Date/time:         $(date '+%Y-%m-%d %H:%M:%S')"
echo "Operating system:  $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Kernel version:    $(uname -r)"
echo "Uptime:            $(uptime -p)"
echo "CPU:               $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs) ($(nproc) cores)"
echo "Memory:            $(free -h | awk '/^Mem:/ {print $3 " used / " $2 " total"}')"
echo "Current directory: $(pwd)"
echo "=============================="

log "Completed system information check"
exit 0
