#!/bin/bash
set -e

# 1. Variabel Lingkungan
RELEASES_BRANCH="${1:-openwrt:25.12.1}"
make_path="/builder"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
output_path="${GITHUB_WORKSPACE}/output"
custom_files_path="${GITHUB_WORKSPACE}/files"

# Status Colors
STEPS="[\033[95m STEPS \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

# FIX PERMISSION: Memberikan izin tulis pada folder LVM ke user runner
sudo chown -R runner:runner "${make_path}"

# 2. Download ImageBuilder (Target ARMSR/ARMV8)
download_imagebuilder() {
    cd "${make_path}"
    echo -e "${STEPS} Downloading OpenWrt 25.12.1 ARMSR..."
    
    URL="https://downloads.openwrt.org/releases/25.12.1/targets/armsr/armv8/openwrt-imagebuilder-25.12.1-armsr-armv8.Linux-x86_64.tar.zst"
    
    wget -qO ib_file.tar.zst "${URL}" || { echo -e "${ERROR} Gagal download!"; exit 1; }
    
    zstd -d ib_file.tar.zst -c | tar -x -C . --strip-components=0
    mv -f openwrt-imagebuilder-* "${openwrt_dir}"
    rm -f ib_file.tar.zst
}

# 3. Add Custom Files & Permissions
custom_files() {
    cd "${imagebuilder_path}"
    if [[ -d "${custom_files_path}" ]]; then
        echo -e "${STEPS} Memproses File Kustom..."
        mkdir -p files
        cp -rf "${custom_files_path}/." files/
        
        # Set Izin Root & Executable
        sudo chown -R 0:0 files/
        find files/ -type d -exec chmod 755 {} +
        find files/ -type f -exec chmod 644 {} +
        for dir in "bin" "sbin" "usr/bin" "usr/sbin" "etc/init.d" "etc/uci-defaults"; do
            [ -d "files/$dir" ] && find "files/$dir" -type f -exec chmod 755 {} +
        done
    fi
}

# 4. Rebuild Firmware (Target ARMSR)
rebuild_firmware() {
    cd "${imagebuilder_path}"
    echo -e "${STEPS} Membangun Rootfs ARMSR..."

    # Daftar paket (sesuai daftar Anda)
    my_packages="base-files ca-bundle dnsmasq-full dropbear e2fsprogs firewall4 fstools \
        kmod-button-hotplug kmod-nft-offload libc libgcc libustream-mbedtls logd \
        mkf2fs mtd netifd nftables odhcp6c odhcpd-ipv6only partx-utils ppp ppp-mod-pppoe procd-ujail \
        uci uclient-fetch urandom-seed urngd luci luci-compat luci-lib-base kmod-usb-net-huawei-cdc-ncm \
        kmod-usb-net kmod-usb-net-rndis luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full \
        luci-mod-network kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
        kmod-mii luci-mod-status luci-mod-system luci-proto-3g luci-proto-mbim mbim-utils picocom minicom \
        luci-proto-ncm luci-proto-ppp luci-proto-qmi screen kmod-tun ttyd kmod-usb-atm kmod-macvlan \
        kmod-usb-net-cdc-ncm kmod-usb-net-cdc-mbim luci-proto-modemmanager modemmanager modemmanager-rpcd \
        libqmi libmbim glib2 ipset libcap libcap-bin ruby ruby-yaml kmod-inet-diag kmod-nft-tproxy \
        ip-full php8 haproxy tcpdump UDPspeeder irqbalance kmod-dummy bc uhttpd uhttpd-mod-ubus unzip \
        uqmi usb-modeswitch uuidgen zstd wwan ziptool zoneinfo-asia zoneinfo-core zram-swap bash apk \
        openssh-sftp-server adb wget-ssl httping htop jq tar coreutils-sleep coreutils-stat \
        kmod-nls-utf8 kmod-usb-storage cgi-io chattr comgt comgt-ncm coremark coreutils coreutils-base64 \
        coreutils-nohup kmod-usb-net-sierrawireless kmod-usb-serial-qualcomm kmod-usb-serial-sierrawireless \
        luci-app-ttyd luci-theme-material wpad-openssl iw iwinfo wireless-regdb netdata vnstat2 vnstati2 \
        php8-cli php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv \
        php8-mod-mbstring wpad-basic-mbedtls hostapd-common luci-app-cpufreq"

    fakeroot make image PROFILE="generic" PACKAGES="${my_packages}" FILES="files" V=s

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS} Build Berhasil!"
        mkdir -p "${output_path}"
        # COPY DARI ARMSYSTEM (ARMSR/ARMV8)
        cp bin/targets/armsr/armv8/*.tar.* "${output_path}/"
    else
        echo -e "${ERROR} Build Gagal!"; exit 1
    fi
}

# Eksekusi
download_imagebuilder
custom_files
rebuild_firmware
