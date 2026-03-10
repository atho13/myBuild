#!/bin/bash

BRANCH=$1
BUILD_DIR="/builder/openwrt"

# 1. Persiapan Direktori Files
mkdir -p ${BUILD_DIR}/files/etc/config
mkdir -p ${BUILD_DIR}/files/usr/bin
mkdir -p ${BUILD_DIR}/files/etc/init.d

# 2. Download Image Builder
IMAGE_BUILDER_URL="https://downloads.openwrt.org{BRANCH}/targets/armvirt/64/openwrt-imagebuilder-${BRANCH}-armvirt-64.Linux-x86_64.tar.xz"
wget -qO- $IMAGE_BUILDER_URL | tar Jx --strip-components=1 -C ${BUILD_DIR}
cd ${BUILD_DIR}

# 3. KONFIGURASI WIFI (SSID: OpenWrt_P212)
cat <<EOF > files/etc/config/wireless
config wifi-device 'radio0'
	option type 'mac80211'
	option channel '11'
	option hwmode '11g'
	option path 'platform/soc/d0070000.mmc/mmc_host/mmc1/mmc1:0001/mmc1:0001:1'
	option htmode 'HT20'
	option disabled '0'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'FRDMX'
	option encryption 'psk2'
	option key 'root'
EOF

# 4. KONFIGURASI NETWORK (Auto-Modem USB)
cat <<EOF > files/etc/config/network
config interface 'loopback'
	option ifname 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'lan'
	option type 'bridge'
	option ifname 'eth0'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'

config interface 'wan_usb'
	option ifname 'usb0'
	option proto 'dhcp'
	option metric '10'
EOF

# 5. KONFIGURASI MWAN3 (Anti-Loss / Auto-Reconnect)
# Menjaga koneksi tetap aktif jika IP berubah atau koneksi timeout
cat <<EOF > files/etc/config/mwan3
config interface 'wan_usb'
	option enabled '1'
	list track_ip '8.8.8.8'
	list track_ip '1.1.1.1'
	option reliability '1'
	option count '1'
	option timeout '2'
	option interval '5'
	option down '3'
	option up '2'
EOF

# 6. SKRIP PINGER (Keep-Alive)
cat <<EOF > files/usr/bin/pinger.sh
#!/bin/sh
# Ping ringan tiap 10 detik agar jalur modem tidak 'idle'
while true; do
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    sleep 10
done
EOF
chmod +x files/usr/bin/pinger.sh

# Jalankan pinger saat booting via rc.local
cat <<EOF > files/etc/rc.local
/usr/bin/pinger.sh &
exit 0
EOF

# 7. DAFTAR PAKET (Clean + Modem + Stabilizer)
PACKAGES="luci luci-app-amlogic kmod-amlogic-fdu \
usb-modeswitch kmod-usb-net-cdc-ether kmod-usb-net-rndis \
brcmfmac-firmware-43430-sdio brcmfmac-firmware-43455-sdio \
kmod-brcmfmac kmod-cfg80211 kmod-mac80211 \
ppp ppp-mod-pppoe \
mwan3 luci-app-mwan3 \
bash curl wget htop coreutils-nohup \
-dnsmasq dnsmasq-full"

# 8. EKSEKUSI BUILD
make image PROFILE="Default" PACKAGES="$PACKAGES" FILES="files"

echo "Build Berhasil! Gunakan 'luci-app-amlogic' untuk instalasi ke EMMC."
