
#!/bin/bash
# Check required commands
ERROR_LOG="$HOME/server-monitor/error.log"
mkdir -p "$(dirname "$ERROR_LOG")"

REQUIRED_COMMANDS=(mpstat free awk df uptime ps)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        ERROR_MESSAGE="ERROR: Required command '$cmd' is not installed."
        echo "$ERROR_MESSAGE" | tee -a "$ERROR_LOG"
        exit 1
    fi
done

echo "All required commands are available."

# ==========================================
# Linux Server Health Monitoring
# Author: Harshika
# ==========================================

# Thresholds
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=80

# Report directory
REPORT_DIR="$HOME/server-monitor/reports"
mkdir -p "$REPORT_DIR"

# Log Rotation - Delete reports older than 7 days
find "$REPORT_DIR" -type f -name "health_report_*.log" -mtime +7 -delete

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORT_DIR/health_report_$TIMESTAMP.log"

# Function to write output
log() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# Function to check resource health
check_status() {
    local NAME="$1"
    local VALUE="$2"

    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    if awk -v v="$VALUE" 'BEGIN {exit !(v >= 80)}'; then
        echo -e "${RED}RED: $NAME usage is CRITICAL (${VALUE}%)${NC}" | tee -a "$REPORT_FILE"

    elif awk -v v="$VALUE" 'BEGIN {exit !(v >= 70)}'; then
        echo -e "${YELLOW}YELLOW: $NAME usage is WARNING (${VALUE}%)${NC}" | tee -a "$REPORT_FILE"

    else
        echo -e "${GREEN}GREEN: $NAME usage is NORMAL (${VALUE}%)${NC}" | tee -a "$REPORT_FILE"
    fi
}

# CPU Usage
CPU_IDLE=$(mpstat 1 1 | awk '/Average:/ {print $NF}')

CPU_USAGE=$(awk -v idle="$CPU_IDLE" \
'BEGIN {printf "%.2f", 100-idle}')

# RAM Usage
RAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/^Mem:/ {print $3}')
RAM_USAGE=$(awk -v used="$RAM_USED" -v total="$RAM_TOTAL" \
    'BEGIN {if(total>0) printf "%.2f", used/total*100; else print 0}')

# Swap Usage
SWAP_TOTAL=$(free -m | awk '/^Swap:/ {print $2}')
SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')

if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_USAGE=$(awk -v used="$SWAP_USED" -v total="$SWAP_TOTAL" \
    'BEGIN {printf "%.2f", used/total*100}')
else
    SWAP_USAGE=0
fi

# Disk Usage
DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

# Uptime
UPTIME=$(uptime -p)

# Load Average
LOAD_AVERAGE=$(awk '{print $1, $2, $3}' /proc/loadavg)

# Running Processes
PROCESSES=$(ps -e --no-headers | wc -l)

# Generate Report
log "========================================"
log "       LINUX SERVER HEALTH REPORT"
log "========================================"
log "Date: $(date)"
log "Hostname: $(hostname)"
log "----------------------------------------"

log "CPU Usage: ${CPU_USAGE}%"
log "RAM Usage: ${RAM_USAGE}%"
log "Swap Usage: ${SWAP_USAGE}%"
log "Disk Usage: ${DISK_USAGE}%"
log "System Uptime: $UPTIME"
log "Load Average: $LOAD_AVERAGE"
log "Running Processes: $PROCESSES"

log "----------------------------------------"
log "           HEALTH STATUS"
log "----------------------------------------"

check_status "CPU" "$CPU_USAGE"
check_status "RAM" "$RAM_USAGE"
check_status "SWAP" "$SWAP_USAGE"
check_status "DISK" "$DISK_USAGE"

log "========================================"
log "Report saved at: $REPORT_FILE"
log "========================================"
