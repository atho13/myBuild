#!/bin/sh
# For Frdmx-Wrt Community..

if ! swapon -s | grep -q "zram0"; then
    if [ -b "/dev/zram0" ]; then
        logger -t "Frdmx-Cleaner" "[*] Menginisialisasi virtual RAM ZRAM0 murni..."
        swapoff /dev/zram0 >/dev/null 2>&1
        
        if [ -f "/sys/block/zram0/comp_algorithm" ]; then
            echo "lz4" > /sys/block/zram0/comp_algorithm 2>/dev/null
        fi
        
        if [ -f "/sys/block/zram0/disksize" ]; then
            echo "268435456" > /sys/block/zram0/disksize 2>/dev/null
        fi
        
        mkswap /dev/zram0 >/dev/null 2>&1
        swapon -p 32767 /dev/zram0 >/dev/null 2>&1
        sysctl -w vm.swappiness=20 >/dev/null 2>&1
        logger -t "Frdmx-Cleaner" "[+] Sukses mengaktifkan Native ZRAM 256MB (LZ4) & Swappiness Mod."
    else
        logger -t "Frdmx-Cleaner" "[!] Peringatan: Gagal memuat ZRAM. Paket kmod-zram belum terkompilasi di kernel!"
    fi
else
    logger -t "Frdmx-Cleaner" "[*] Info: Native ZRAM sudah aktif dan berjalan normal."
fi

sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
logger -t "Frdmx-Cleaner" "[+] Memori cache sistem berhasil dibersihkan."

for LOG_DIR in /tmp/log /var/log; do
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -type f -name "*.log" 2>/dev/null | while read -r logfile; do
            if [ -f "$logfile" ]; then
                if [ $(wc -c < "$logfile" 2>/dev/null || echo 0) -gt 1048576 ] || [ $(wc -l < "$logfile" 2>/dev/null || echo 0) -gt 5000 ]; then
                    echo "" > "$logfile"
                    logger -t "Frdmx-Cleaner" "[*] Berkas log berukuran besar berhasil dipangkas: $(basename $logfile)"
                fi
            fi
        done
    fi
done

exit 0
