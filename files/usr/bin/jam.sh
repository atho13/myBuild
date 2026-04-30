#!/bin/sh
# Wajib: install curl

TIME_HTTP=$(curl -sI google.com | grep -i '^Date:' | cut -d' ' -f3-7)

if [ -n "$TIME_HTTP" ]; then
    date -s "$TIME_HTTP" > /dev/null 2>&1
    echo "Sinkronisasi jam via HTTP Berhasil"
else
    echo "HTTP gagal, mencoba jalur NTP..."
    ntpd -n -q -p ntp.bmkg.go.id -p 0.id.pool.ntp.org -p ntp.telkom.net
fi

echo "Jam saat ini: $(date)"
