#!/bin/bash
# for FRDMX-Wrt Community

pkill -f cake-autorate.sh 2>/dev/null
rm -rf /var/run/cake-autorate/* 2>/dev/null
sleep 1

ALL_WANS=$(ip route show | awk '/default/ {print $5}' | sort -u)

if [ -z "$ALL_WANS" ]; then
    ALL_WANS=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'usb|rndis|wwan|rmnet|wlan|eth|enp|wan' | sort -u)
fi

if [ -z "$ALL_WANS" ]; then
    logger -t "Frdmx-Launcher" "[WARN] Jalur internet tidak ditemukan. Engine masuk mode standby..."
    exit 0
fi

DYNAMIC_WAN_COUNT=0
for WAN_DEV in $ALL_WANS; do
    if echo "$WAN_DEV" | grep -qE 'lo|br-|tun|wireguard|wg'; then continue; fi
    if ! echo "$WAN_DEV" | grep -qE '^(eth|enp|wan)'; then
        ((DYNAMIC_WAN_COUNT++))
    fi
done

mkdir -p /var/run/cake-autorate

for WAN_DEV in $ALL_WANS; do

    if echo "$WAN_DEV" | grep -qE 'lo|br-|tun|wireguard|wg'; then continue; fi
    
    if echo "$WAN_DEV" | grep -qE '^(eth|enp|wan)'; then
        logger -t "Frdmx-Engine" "[GIGABIT-MODE] Terdeteksi ISP LAN pada $WAN_DEV. Menerapkan CAKE Statis (Unlimited)."
        tc qdisc replace dev "$WAN_DEV" root cake diffserv3 triple-isolate nat wash rtt 100ms >/dev/null 2>&1
        continue
    fi
    
    if [ "$DYNAMIC_WAN_COUNT" -gt 1 ]; then
        logger -t "Frdmx-Engine" "[MULTI-WAN MODE] Mengaktifkan CAKE Statis pada br-lan untuk isolasi trafik RT/RW Net."
        tc qdisc replace dev "br-lan" root cake diffserv3 triple-isolate nonat nowash rtt 100ms >/dev/null 2>&1
        tc qdisc replace dev "$WAN_DEV" root cake diffserv3 triple-isolate nat wash RTT 100ms >/dev/null 2>&1
        continue
    fi
    
    logger -t "Frdmx-Engine" "[SINGLE-MODEM MODE] Mengaktifkan CAKE-Autorate Dinamis pada $WAN_DEV -> br-lan."
    
    CONFIG_RAM="/var/run/cake-autorate/config.run.$WAN_DEV.sh"
    cp /root/cake-autorate/config.primary.sh "$CONFIG_RAM"
    
    sed -i "s/ul_if=\"TEMPLATE_WAN\"/ul_if=\"$WAN_DEV\"/" "$CONFIG_RAM"
    sed -i "s/dl_if=\"lo\"/dl_if=\"br-lan\"/" "$CONFIG_RAM"
    
    bash /root/cake-autorate/cake-autorate.sh "$CONFIG_RAM" >/dev/null 2>&1 &
done
