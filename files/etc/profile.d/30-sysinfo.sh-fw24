#!/bin/sh
# Dashboard Info for Frdmx-Wrt Community

[ -f /usr/share/libubox/jshn.sh ] && . /usr/share/libubox/jshn.sh

C_RESET="\e[0m"
C_BOLD="\e[1m"
C_CYAN="\e[1;36m"
C_YELLOW="\e[1;33m"
C_MAGENTA="\e[1;35m"
C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_WHITE="\e[1;37m"
C_BLINK="\e[5m"
SYMBOL="╰┈➤"

hr() {
    local n=${1:-0}
    awk -v n=$n 'BEGIN{split("B KB MB GB TB",s); for(i=1;n>=1024&&i<5;i++)n/=1024; printf "%.2f %s",n,s[i]}'
}

up_str() {
    local t=$(cut -d. -f1 /proc/uptime)
    local d=$((t/86400)) h=$((t/3600%24)) m=$((t/60%60))
    [ $d -gt 0 ] && printf "%dd " $d
    printf "%02dh %02dm" $h $m
}

print_info() {
    printf "${C_MAGENTA}$SYMBOL ${C_YELLOW}%-11s: ${C_CYAN}%b${C_RESET}\n" "$1" "$2"
}

MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "Generic Device")
KERNEL=$(uname -r)

CPU_TEMP="N/A"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    RAW_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    CPU_TEMP=$(awk -v t="$RAW_TEMP" 'BEGIN {printf "%.1f°C", t/1000}')
elif [ -d /sys/class/hwmon ]; then
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/temp1_input" ]; then
            RAW_TEMP=$(cat "$hwmon/temp1_input")
            CPU_TEMP=$(awk -v t="$RAW_TEMP" 'BEGIN {printf "%.1f°C", t/1000}')
            break
        fi
    done
fi

if ip route 2>/dev/null | grep -q "default"; then
    NET_STATUS="${C_GREEN}Connected"
    /usr/sbin/led -r >/dev/null 2>&1
else
    NET_STATUS="${C_RED}${C_BLINK}Disconnected"
fi

eval $(awk '
    NR > 2 {
        clean_if = $1; gsub(/:/, "", clean_if)
        if (clean_if != "lo" && clean_if != "") {
            rx += $2; tx += $10
        }
    } 
    END {
        printf "TOTAL_RX=%d; TOTAL_TX=%d", rx, tx
    }' /proc/net/dev 2>/dev/null)

eval $(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "MEM_T=%d; MEM_A=%d", t*1024, a*1024}' /proc/meminfo)
eval $(df -k / | awk 'NR==2 {printf "ST_T=%d; ST_U=%d; ST_P=%s", $2*1024, $3*1024, $5}')

[ -f /etc/banner ]
echo -e "${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

print_info "Builder"    "FRDMX-Wrt"
print_info "Model"      "$MODEL"
print_info "Kernel"     "$KERNEL"
print_info "CPU Temp"   "${C_RED}$CPU_TEMP"
print_info "Uptime"     "${C_YELLOW}$(up_str)${C_CYAN} | ${C_WHITE}$(date +'%H:%M:%S')"
print_info "Memory"     "${C_GREEN}$(hr $((MEM_T-MEM_A)))${C_CYAN} / ${C_WHITE}$(hr $MEM_T)"
print_info "Storage"    "${C_GREEN}$(hr $ST_U)${C_CYAN} / ${C_WHITE}$(hr $ST_T) (${C_YELLOW}$ST_P${C_CYAN})"
print_info "Total B/W"  "⇩  ${C_GREEN}$(hr $TOTAL_RX)${C_CYAN} | ⇧  ${C_RED}$(hr $TOTAL_TX)"
print_info "Net Status" "$NET_STATUS"

echo -e "${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
