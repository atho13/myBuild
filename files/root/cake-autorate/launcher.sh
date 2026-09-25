#!/bin/bash
# for FRDMX-Wrt Community

killall -9 cake-autorate.sh fping 2>/dev/null
rm -rf /var/run/cake-autorate/* 2>/dev/null
sleep 1

ALL_WANS=$(ip route show | awk '/default/ {print $5}')
[ -z "$ALL_WANS" ] && ALL_WANS=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'usb|rndis|wwan|rmnet|utun|tun|wan|eth|enp' | sort -u)

if [ -z "$ALL_WANS" ]; then
    logger -t "Frdmx-Launcher" "[WARN] Jaringan WAN belum siap. Engine masuk mode standby..."
    exit 0
fi

mkdir -p /var/run/cake-autorate

for WAN_DEV in $ALL_WANS; do
    if echo "$WAN_DEV" | grep -qE 'lo|br-'; then continue; fi
    
    if echo "$WAN_DEV" | grep -qE 'eth|enp'; then
        logger -t "Frdmx-Engine" "[GIGABIT-MODE] Menerapkan CAKE Unlimited pada $WAN_DEV (Kecepatan 980 Mbps Terjamin)"
        
        tc qdisc replace dev "$WAN_DEV" root cake diffserv3 triple-isolate nat wash rtt 100ms >/dev/null 2>&1
        continue
    fi
    
    logger -t "Frdmx-Engine" "[MODEM-MODE] Mengaktifkan Dinamis CAKE-Autorate pada $WAN_DEV untuk Stabilitas Ping"
    
    CONFIG_RAM="/var/run/cake-autorate/config.run.$WAN_DEV.sh"
    cp /root/cake-autorate/config.primary.sh "$CONFIG_RAM"
    
    sed -i "s/ul_if=\"TEMPLATE_WAN\"/ul_if=\"$WAN_DEV\"/" "$CONFIG_RAM"
    sed -i "s/dl_if=\"TEMPLATE_WAN\"/dl_if=\"$WAN_DEV\"/" "$CONFIG_RAM"
    
    bash /root/cake-autorate/cake-autorate.sh "$CONFIG_RAM" >/dev/null 2>&1 &
done
