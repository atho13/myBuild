#!/bin/sh
# For Frdmx-Wrt Community

if ! swapon -s | grep -q "zram"; then
    zramctl /dev/zram0 --size 256M --algorithm lz4 2>/dev/null
    mkswap /dev/zram0 2>/dev/null
    swapon -p 32767 /dev/zram0 2>/dev/null
    
    sysctl -w vm.swappiness=60 >/dev/null 2>&1
    logger -t "Frdmx-Cleaner" "[+] Sukses mengaktifkan ZRAM 256MB (LZ4) & Optimasi Swappiness."
else
    logger -t "Frdmx-Cleaner" "[*] Info: ZRAM sudah aktif dan berjalan normal."
fi

sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
logger -t "Frdmx-Cleaner" "[+] Memori cache sistem berhasil dibersihkan."

for LOG_DIR in /tmp/log /var/log; do
    if [ -d "$LOG_DIR" ]; then
        for logfile in "$LOG_DIR"/*.log "$LOG_DIR"/*/*.log; do
            [ -f "$logfile" ] && [ $(wc -c < "$logfile") -gt 1048576 ] && echo "" > "$logfile"
        done
    fi
done

exit 0
