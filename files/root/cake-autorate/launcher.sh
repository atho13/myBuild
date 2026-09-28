#!/bin/bash
# for FRDMX-Wrt Community

mkdir -p /var/run/cake-autorate

ALL_WANS=""
WAN_ZONE_INDEX=$(uci show firewall | grep -E "\.name='wan'" | cut -d'[' -f2 | cut -d']' -f1)

if [ -n "$WAN_ZONE_INDEX" ]; then
    WAN_NETWORKS=$(uci -q get firewall.@zone["$WAN_ZONE_INDEX"].network)
else
    WAN_NETWORKS="wan wan6"
fi

for net in $WAN_NETWORKS; do
    dev=$(uci -q get network.$net.device || uci -q get network.$net.ifname)
    if [ -n "$dev" ] && [ "$dev" != "lo" ]; then
        ALL_WANS="$ALL_WANS $dev"
    fi
done


ALL_WANS=$(echo "$ALL_WANS" | tr ' ' '\n' | sort -u | tr '\n' ' ')


for running_conf in /var/run/cake-autorate/config.run.*.sh; do
    [ -e "$running_conf" ] || continue
    current_dev=$(basename "$running_conf" | cut -d'.' -f3)
    if ! echo "$ALL_WANS" | grep -q "$current_dev"; then
        logger -t "Frdmx-Cleaner" "Modem/Interface $current_dev dicopot atau tidak aktif. Membersihkan proses..."
        pkill -9 -f "config.run.$current_dev.sh"
        rm -f "$running_conf"
    fi
done

if [ -z "$ALL_WANS" ]; then
    logger -t "Frdmx-Launcher" "[WARN] Jaringan internet di Zona WAN tidak ditemukan. Engine standby..."
    exit 0
fi


for WAN_DEV in $ALL_WANS; do

    if echo "$WAN_DEV" | grep -qE 'lo|br-|tun|wireguard|wg'; then continue; fi
    
    if pgrep -f "config.run.$WAN_DEV.sh" > /dev/null; then
        continue
    fi

    LOGICAL_WAN=$(uci -q show network | grep ".device='$WAN_DEV'" | cut -d'.' -f2 | head -n1)
    [ -z "$LOGICAL_WAN" ] && LOGICAL_WAN="wan"

    logger -t "Frdmx-Engine" "[START] Menyalakan CAKE-Autorate Dinamis pada $WAN_DEV (${LOGICAL_WAN^^})."
    
    CONFIG_RAM="/var/run/cake-autorate/config.run.$WAN_DEV.sh"
    cp /root/cake-autorate/config.primary.sh "$CONFIG_RAM"
    
    sed -i "s/ul_if=\"TEMPLATE_WAN\"/ul_if=\"$WAN_DEV\"/" "$CONFIG_RAM"
    sed -i "s/dl_if=\"lo\"/dl_if=\"br-lan\"/" "$CONFIG_RAM"
    
    bash /root/cake-autorate/cake-autorate.sh "$CONFIG_RAM" >/dev/null 2>&1 &
    
    if echo "$WAN_DEV" | grep -q '^eth'; then
        (
            sleep 2

            if ! tc qdisc show dev "$WAN_DEV" | grep -q "cake"; then
                logger -t "Frdmx-Bypass" "Mengunci ulang otoritas CAKE pada interface $WAN_DEV..."
                tc qdisc replace dev "$WAN_DEV" root cake diffserv3 triple-isolate nat wash rtt 100ms >/dev/null 2>&1
            fi
        ) &
    fi
done
