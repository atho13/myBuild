#!/bin/sh
# FRDMX-Wrt
. /usr/share/libubox/jshn.sh
grep -q 'debug' /proc/cmdline && n=10 || n=2
dmesg -n $n

C_RESET="\e[0m"
C_BOLD="\e[1m"
C_CYAN="\e[1;36m"
C_YELLOW="\e[1;33m"
C_MAGENTA="\e[1;35m"
C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_WHITE="\e[1;37m"
SYMBOL="╰┈➤"

hr() {
    local n=${1:-0}
    awk -v n=$n 'BEGIN{split("B KB MB GB TB",s); for(i=1;n>=1024&&i<5;i++)n/=1024; printf "%.2f %s",n,s[i]}'
}

up_str() {
    local t=$(cut -d. -f1 /proc/uptime)
    local d=$((t/86400))
    local h=$((t/3600%24))
    local m=$((t/60%60))
    [ $d -gt 0 ] && printf "%dd " $d
    printf "%02dh %02dm" $h $m
}

print_info() {
    printf "${C_MAGENTA}$SYMBOL ${C_YELLOW}%-13s: ${C_CYAN}%s${C_RESET}\n" "$1" "$2"
}

MODEL=$(cat /tmp/sysinfo/model 2>/dev/null || echo "Generic Device")
ARCH=$(uname -m)

if [ -f "/sys/class/hwmon/hwmon2/temp1_input" ]; then
    CPU_TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/hwmon/hwmon2/temp1_input)
elif [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
    CPU_TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
else
    CPU_TEMP="N/A"
fi

eval $(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "MEM_T=%d; MEM_A=%d", t*1024, a*1024}' /proc/meminfo)
eval $(df -k / | awk 'NR==2 {printf "ST_T=%d; ST_U=%d; ST_P=%s", $2*1024, $3*1024, $5}')

echo -e "${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
print_info "Device Model" "$MODEL"
print_info "Architecture" "$ARCH"
print_info "CPU Temp" "$CPU_TEMP"
print_info "Uptime" "$(up_str) | $(date +'%H:%M:%S')"
print_info "Memory" "$(hr $((MEM_T-MEM_A))) / $(hr $MEM_T)"
print_info "Storage" "$(hr $ST_U) / $(hr $ST_T) ($ST_P)"

echo -e "${C_RED}------------------------------------------------${C_RESET}"
echo -e "${C_YELLOW}Exmple  : ${C_CYAN}apk add --allow-untrusted ./*.apk${C_RESET}"
echo -e "${C_RED}------------------------------------------------${C_RESET}"
printf "${C_WHITE}%-15s %s${C_RESET}\n" " COMMAND" "DESCRIPTION"
printf "${C_CYAN}%-15s ${C_RESET}%s\n" " apk add" "Install a package"
printf "${C_CYAN}%-15s ${C_RESET}%s\n" " apk del" "Remove a package"
printf "${C_CYAN}%-15s ${C_RESET}%s\n" " apk upgrade" "Upgrade all packages"
printf "${C_CYAN}%-15s ${C_RESET}%s\n" " apk info" "List installed packages"
printf "${C_CYAN}%-15s ${C_RESET}%s\n" " apk update" "Update package lists"
echo -e "${C_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
export HOME=$(grep -e "^${USER:-root}:" /etc/passwd | cut -d ":" -f 6)
export HOME=${HOME:-/root}
export PS1='\u@\h:\w\$ '
[ -n "$LC_ALL" ] || export LC_ALL="en_US.UTF-8"
