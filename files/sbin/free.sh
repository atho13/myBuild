#!/bin/sh
# frdmx cleaner + Automatic ZRAM Init - Optimized for Performance

if ! swapon -s | grep -q "zram"; then
    zramctl /dev/zram0 --size 256M --algorithm lz4 2>/dev/null
    mkswap /dev/zram0 2>/dev/null
    swapon -p 32767 /dev/zram0 2>/dev/null
    
else

    swapoff -a && swapon -a
fi

sync
echo 3 > /proc/sys/vm/drop_caches

for LOG_DIR in /tmp/log /var/log; do
    if [ -d "$LOG_DIR" ]; then
        for logfile in "$LOG_DIR"/*.log "$LOG_DIR"/*/*.log; do
            [ -f "$logfile" ] && [ $(wc -c < "$logfile") -gt 1048576 ] && echo "" > "$logfile"
        done
    fi
done

exit 0
