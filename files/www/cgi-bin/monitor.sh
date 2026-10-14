#!/bin/sh
echo "Content-Type: application/json"
echo ""
echo "{"

# --- 1. DATA WAKTU & INTERNET ---
uptime_str=$(uptime | awk -F'(,  |, )' '{print $1}' | sed 's/.*up //')
time_now=$(date +"%H:%M:%S")
if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
    internet="Online"
else
    internet="Offline"
fi

echo "  \"system\": {"
echo "    \"time\": \"$time_now\","
echo "    \"uptime\": \"$uptime_str\","
echo "    \"internet\": \"$internet\""
echo "  },"

# --- 2. AMBIL DATA CPU & SUHU ---
cpu_usage=$(top -n 1 | awk '/^CPU:/ {
    for(i=1; i<=NF; i++) {
        if($i ~ /idl/) {
            idle=substr($(i-1), 1, length($(i-1))-1); 
            print 100 - idle;
            exit;
        }
    }
}')
[ -z "$cpu_usage" ] && cpu_usage=0

if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    [ ${#cpu_temp} -gt 3 ] && cpu_temp=$((cpu_temp / 1000))
else
    cpu_temp="N/A"
fi

echo "  \"cpu\": $cpu_usage,"
echo "  \"temperature\": \"$cpu_temp\","

# --- 3. DATA RAM ---
echo "  \"ram\": {"
awk '
/^MemTotal:/ { total = $2 }
/^MemAvailable:/ { available = $2 }
/^MemFree:/ && !available { free = $2 }
/^Buffers:/ { buffers = $2 }
/^Cached:/ { cached = $2 }
END {
    if (!available) available = free + buffers + cached;
    used = total - available;
    percent = (total > 0) ? int((used / total) * 100 + 0.5) : 0;
    printf "    \"total\": %d,\n", total;
    printf "    \"available\": %d,\n", available;
    printf "    \"used\": %d,\n", used;
    printf "    \"percent\": %d\n", percent;
}' /proc/meminfo
echo "  },"

# --- 4. AMBIL SEMUA INTERFACE SECARA DINAMIS ---
echo "  \"interfaces\": ["
first=1
for iface in $(awk 'NR>2 {sub(/:/,""); print $1}' /proc/net/dev | grep -v "lo"); do
    ip_addr=$(ip addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
    [ -z "$ip_addr" ] && ip_addr="No IP"
    if [ $first -eq 0 ]; then echo ","; fi
    printf "    { \"name\": \"$iface\", \"ip\": \"$ip_addr\" }"
    first=0
done
echo ""
echo "  ],"

# --- 5. DATA TRAFIK ALL INTERFACES ---
echo "  \"data\": {"
awk '
NR > 2 {
    sub(/^[ \t]+/, "");
    split($0, a, ":");
    name = a;
    if (name != "lo") {
        split(a, b, " ");
        if (count > 0) print ",";
        printf "    \"%s\": { \"rx\": %s, \"tx\": %s }", name, b, b;
        count++;
    }
}' /proc/net/dev
echo ""
echo "  }"
echo "}"
