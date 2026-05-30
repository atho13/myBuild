#!/bin/bash
set -e

# 1. Variabel Jalur
make_path="/builder"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
output_path="${GITHUB_WORKSPACE}/output"
custom_files_path="${GITHUB_WORKSPACE}/files"

# Status Colors
STEPS="[\033[95m STEPS \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

# FIX PERMISSION: Memberikan izin tulis agar runner tidak "Permission Denied"
sudo chown -R runner:runner "${make_path}"

# 2. Download ImageBuilder (URL ARMSr/ARMv8)
download_imagebuilder() {
    cd "${make_path}"
    echo -e "${STEPS} Mengunduh ImageBuilder OpenWrt 24.10.6 (ARMSR/ARMV8)..."
    
    URL="https://archive.openwrt.org/releases/24.10.6/targets/armsr/armv8/openwrt-imagebuilder-24.10.6-armsr-armv8.Linux-x86_64.tar.zst"
    
    curl -fL -o ib.tar.zst "$URL" || { echo -e "${ERROR} Gagal download!"; exit 1; }
    
    # Verifikasi format file
    if ! file ib.tar.zst | grep -q "Zstandard"; then
        echo -e "${ERROR} File terunduh bukan format Zstandard! Periksa URL."
        exit 1
    fi

    mkdir -p "${openwrt_dir}"
    zstd -d ib.tar.zst -c | tar -x -C "${openwrt_dir}" --strip-components=1
    rm -f ib.tar.zst
    echo -e "${SUCCESS} ImageBuilder berhasil diekstrak."
}

rebuild_firmware() {
    cd "${imagebuilder_path}"
    echo -e "${STEPS} Mengatur konfigurasi ukuran partisi (750MB)..."

    # INJECT KONFIGURASI DISINI
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=750" >> .config
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=64" >> .config

    # ====================================================================
    # SOLUSI DEPENDENSI: KLONING REPO QMODEM LANGSUNG KE FOLDER PACKAGES
    # ====================================================================
    echo -e "${STEPS} Mengunduh Source QModem beserta dependensinya..."
    
    # Membuat folder khusus paket pihak ketiga jika belum ada
    mkdir -p package/qmodem_source
    
    # Kloning repositori QModem langsung ke folder internal ImageBuilder
    git clone --depth 1 -b main https://github.com package/qmodem_source/QModem
    
    # (Opsional) Jika butuh sinkronisasi indeks paket lokal agar terbaca oleh skrip ImageBuilder
    echo -e "${STEPS} Memperbarui indeks paket lokal..."
    # ====================================================================

    echo -e "${STEPS} Membangun Rootfs ARMSR..."

    # Daftar paket gabungan & dibersihkan dari konflik
    # Memasukkan paket-paket QModem langsung ke daftar kompilasi target
    my_packages="-dnsmasq dnsmasq-full base-files dropbear e2fsprogs firewall4 fstools tc-full \
          kmod-button-hotplug kmod-nft-offload libc libgcc libustream-mbedtls logd kmod-tcp-bbr \
          mkf2fs mtd netifd nftables odhcp6c odhcpd-ipv6only partx-utils ppp ppp-mod-pppoe procd-ujail \
          uci uclient-fetch urandom-seed urngd luci luci-compat luci-lib-base kmod-usb-net-huawei-cdc-ncm \
          kmod-usb-net kmod-usb-net-rndis luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full \
          luci-mod-network kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
          kmod-mii luci-mod-status luci-mod-system luci-proto-3g luci-proto-mbim mbim-utils picocom minicom \
          luci-proto-ncm luci-proto-ppp luci-proto-qmi screen kmod-tun ttyd kmod-usb-atm kmod-macvlan \
          kmod-usb-net-cdc-ncm kmod-usb-net-cdc-mbim luci-proto-modemmanager modemmanager modemmanager-rpcd \
          libqmi libmbim glib2 ipset libcap libcap-bin ruby ruby-yaml kmod-inet-diag kmod-nft-tproxy \
          ip-full php8 tcpdump irqbalance bc uhttpd uhttpd-mod-ubus unzip qmi-utils kmod-usb-net-qmi-wwan \
          uqmi usb-modeswitch uuidgen zstd wwan ziptool zoneinfo-asia zoneinfo-core zram-swap bash \
          openssh-sftp-server adb wget-ssl httping htop jq tar coreutils-sleep coreutils-stat nano fping \
          kmod-nls-utf8 kmod-usb-storage cgi-io chattr comgt comgt-ncm coremark coreutils coreutils-base64 \
          coreutils-nohup kmod-usb-net-sierrawireless kmod-usb-serial-qualcomm kmod-usb-serial-sierrawireless \
          luci-app-ttyd luci-theme-material iw iwinfo netdata vnstat2 vnstati2 php8-mod-mbstring php8-cli \
          php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv \
          kmod-mhi-net kmod-mhi-bus kmod-mhi-pci-generic kmod-mhi-wwan-ctrl kmod-mhi-wwan-mbim kmod-sched-cake \
          luci-app-qmodem luci-app-qmodem-sms sms-tool"
        
    # Proses Image Building
    [ -d "${custom_files_path}" ] && chmod -R +x "${custom_files_path}/etc/uci-defaults"
    make image PROFILE="generic" \
               PACKAGES="${my_packages}" \
               FILES="${custom_files_path}" \
               V=s
               
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS} Build Berhasil!"
        mkdir -p "${output_path}"
        cp bin/targets/armsr/armv8/*.tar.* "${output_path}/" 2>/dev/null || true
    else
        echo -e "${ERROR} Build Gagal!"; exit 1
    fi
}

# Jalankan Fungsi Utama
download_imagebuilder
rebuild_firmware

# Melihat Log
ls -R ${GITHUB_WORKSPACE}/output
