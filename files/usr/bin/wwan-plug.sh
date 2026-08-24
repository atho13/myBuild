#!/bin/bash

# Credit to the Siltesa (Adapted for Procd Service)
# Daftar VID (Vendor ID) untuk modul WWAN

vids=("2c7c" "2cb7" "1199" "8087" "413c" "1bc7" "03f0" "1e2d")

echo "[WWAN-Service] Memulai layanan pemantau modem..." > /dev/kmsg

while true; do
    
    interface_status=$(ifstatus wwan 2>/dev/null | jq -r '.up' 2>/dev/null)

    if [ "$interface_status" = "true" ]; then
        # Jeda 60 detik sebelum mengecek status internet lagi
        sleep 60
        continue
    fi

    echo "[WWAN-Service] Interface wwan down atau modem baru dicolok. Mencari modul WWAN..." > /dev/kmsg
    
    MODEM_FOUND=0
    for vid in "${vids[@]}"; do
        idvendor_file=$(grep -l "$vid" /sys/bus/usb/devices/*/idVendor 2>/dev/null | head -n 1)

        if [ -n "$idvendor_file" ]; then
            device_dir=$(dirname "$idvendor_file")
            device_path=$(basename "$device_dir")

            echo "[WWAN-Service] Modem dengan VID $vid ditemukan di port: $device_path" > /dev/kmsg
            
            current_dev=$(uci -q get network.wwan.device)
            if [ "$current_dev" != "$device_path" ]; then
                uci set network.wwan.device="$device_path"
                uci -q commit network
            fi
            
            MODEM_FOUND=1
            break
        fi
    done

    if [ $MODEM_FOUND -eq 1 ]; then
        echo "[WWAN-Service] Mencoba mengaktifkan antarmuka 'wwan'..." > /dev/kmsg
        ifup wwan
    else
        echo "[WWAN-Service] Tidak ada modem rakitan yang terdeteksi." > /dev/kmsg
    fi

    sleep 30
done
