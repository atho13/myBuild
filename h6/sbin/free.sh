#!/bin/sh
# For Frdmx-Wrt Community..

if ! swapon -s | grep -q "zram0"; then
    if [ -b "/dev/zram0" ]; then
        logger -t "Frdmx-Cleaner" "[*] Menginisialisasi virtual RAM ZRAM0 murni..."
        swapoff /dev/zram0 >/dev/null 2>&1
        
        if [ -f "/sys/block/zram0/comp_algorithm" ]; then
            AVAILABLE_ALGO=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null)
            if echo "$AVAILABLE_ALGO" | grep -q "zstd"; then
                echo "zstd" > /sys/block/zram0/comp_algorithm 2>/dev/null
                ALGO="ZSTD"
            elif echo "$AVAILABLE_ALGO" | grep -q "lz4"; then
                echo "lz4" > /sys/block/zram0/comp_algorithm 2>/dev/null
                ALGO="LZ4"
            else
                ALGO="Default"
            fi
        fi
        
        if [ -f "/sys/block/zram0/disksize" ]; then
            TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null)
            if [ -n "$TOTAL_MEM" ] && [ "$TOTAL_MEM" -gt 0 ]; then

                ZRAM_SIZE=$((TOTAL_MEM * 1024 / 2))

                [ "$ZRAM_SIZE" -lt 134217728 ] && ZRAM_SIZE=134217728
            else
                ZRAM_SIZE=268435456
            fi
            echo "$ZRAM_SIZE" > /sys/block/zram0/disksize 2>/dev/null
            ZRAM_MB=$((ZRAM_SIZE / 1024 / 1024))
        fi
        
        mkswap /dev/zram0 >/dev/null 2>&1
        swapon -p 32767 /dev/zram0 >/dev/null 2>&1
        sysctl -w vm.swappiness=60 >/dev/null 2>&1
        logger -t "Frdmx-Cleaner" "[+] Sukses mengaktifkan Native ZRAM ${ZRAM_MB}MB ($ALGO) & Swappiness Mod."
    else
        logger -t "Frdmx-Cleaner" "[!] Peringatan: Gagal memuat ZRAM. Paket kmod-zram belum terkompilasi di kernel!"
    fi
else
    logger -t "Frdmx-Cleaner" "[*] Info: Native ZRAM sudah aktif dan berjalan normal."
fi

sync
echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
logger -t "Frdmx-Cleaner" "[+] Memori cache sistem berhasil dibersihkan dengan aman."

for LOG_DIR in /tmp/log /var/log; do
    if [ -d "$LOG_DIR" ]; then
        # Menggunakan find agar kalkulasi ukuran byte (>1MB) dilakukan instan di memory
        find "$LOG_DIR" -type f -name "*.log" -size +1M 2>/dev/null | while read -r logfile; do
            if [ -f "$logfile" ]; then
                echo "" > "$logfile"
                logger -t "Frdmx-Cleaner" "[*] Berkas log berukuran besar (>1MB) berhasil dipangkas: $(basename "$logfile")"
            fi
        done
    fi
done

exit 0
