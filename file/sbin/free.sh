#!/bin/sh
# frdmx cleaner - Optimized for Performance & Usability

sync

echo 3 > /proc/sys/vm/drop_caches

for logfile in /tmp/log/*.log; do
    [ -f "$logfile" ] && [ $(wc -c < "$logfile") -gt 1048576 ] && echo "" > "$logfile"
done

exit 0
