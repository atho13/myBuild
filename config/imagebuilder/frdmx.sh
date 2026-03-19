#!/bin/bash

# =================================================================
# OpenWrt 25.12.1 Build Script for Amlogic (STB)
# Path: config/imagebuilder/frdmx.sh
# =================================================================

set -e

# Menangkap input dari Workflow (default ke 25.12.1 jika kosong)
RELEASES_BRANCH="${1:-openwrt:25.12.1}"
BASE=$(echo $RELEASES_BRANCH | cut -d':' -f1)
BRANCH=$(echo $RELEASES_BRANCH | cut -d':' -f2)

# Gunakan direktori /builder sesuai LVM di Workflow
make_path="/builder"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
output_path="${GITHUB_WORKSPACE}/output"
custom_files_path="${GITHUB_WORKSPACE}/files"

# Status Colors
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

error_msg() { echo -e "${ERROR} ${1}"; exit 1; }

# 1. Downloading ImageBuilder (PERBAIKAN URL)
download_imagebuilder() {
    cd "${make_path}"
    echo -e "${STEPS} Downloading ${BASE} ${BRANCH} ImageBuilder..."
    
    # URL LENGKAP (Wajib diarahkan ke file .tar.zst)
    URL="https://downloads.${BASE}.org/releases/${BRANCH}/targets/armvirt/64/${BASE}-imagebuilder-${BRANCH}-armvirt-64.Linux-x86_64.tar.zst"
    
    wget -qO ib_file.tar.zst "${URL}" || error_msg "Gagal download ImageBuilder! Periksa URL: ${URL}"
    
    # Ekstrak menggunakan zstd
    zstd -d ib_file.tar.zst -c | tar -x -C . --strip-components=0
    mv -f *-imagebuilder-* "${openwrt_dir}"
    rm -f ib_file.tar.zst
    echo -e "${SUCCESS} ImageBuilder siap di [ ${imagebuilder_path} ]"
}

# 2. Add Custom Files & Fix Permissions
custom_files() {
    cd "${imagebuilder_path}"
    if [[ -d "${custom_files_path}" ]]; then
        echo -e "${STEPS} Memproses File Kustom dari ${custom_files_path}..."
        mkdir -p files
        cp -rf "${custom_files_path}/." files/

        # PAKSA IZIN AKSES ROOT (0:0)
        sudo chown -R 0:0 files/
        find files/ -type d -exec chmod 755 {} +
        find files/ -type f -exec chmod 644 {} +
        # Binary & Skrip Init wajib 755
        for dir in "bin" "sbin" "usr/bin" "usr/sbin" "etc/init.d" "etc/uci-defaults"; do
            [ -d "files/$dir" ] && find "files/$dir" -type f -exec chmod 755 {} +
        done
        echo -e "${SUCCESS} Izin file disetel ke Root:0755"
    fi
}

# 3. Rebuild Firmware (Daftar Paket S905X Optimal)
rebuild_firmware() {
    cd "${imagebuilder_path}"
    echo -e "${STEPS} Membangun Rootfs untuk SoC Amlogic..."

    # Paket Driver S905X + PHP8 + Netdata + System Tools
    # Catatan: 'apk' ditambahkan karena standar baru 25.12
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
        php8-mod-mbstring wpad-basic-mbedtls hostapd-common"

    # BUILD DENGAN FAKEROOT
    fakeroot make image PROFILE="generic" PACKAGES="${my_packages}" FILES="files" V=s

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS} Rootfs sukses dibuat!"
        mkdir -p "${output_path}"
        cp bin/targets/armvirt/64/*.tar.* "${output_path}/"
    else
        error_msg "Build Gagal!"
    fi
}

# Eksekusi
download_imagebuilder
custom_files
rebuild_firmware
