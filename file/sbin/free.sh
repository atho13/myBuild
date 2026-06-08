#!/bin/sh
#frdmx cleaner
#
sync
echo 3 > /proc/sys/vm/drop_caches
rm -rf /tmp/luci-modulecache
rm -f /tmp/log/*.log 2>/dev/null
exit 0
