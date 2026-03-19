#!/bin/bash

# =================================================================
# OpenWrt 25.12.1 Build Script for Amlogic (STB)
# Path: config/imagebuilder/frdmx.sh
# Optimized for: S905X, APK Manager, Kernel 6.12, Zstandard Support
# =================================================================

set -e

# 1. Konfigurasi Path (Sesuai Struktur Workflow LVM)
RELEASES_BRANCH="${1:-openwrt:25.12.1}"
make_path="/builder"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${GITHUB_WORKSPACE}/files"
output_path="${GITHUB_WORKSPACE}/output"

# Status Colors
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

error_msg() { echo -e "${ERROR} ${1}"; exit 1; }

# FIX PERMISSION: Agar user runner bisa menulis di folder /builder (LVM)
sudo chown -R runner:runner "${make_path}"

# 2. Fungsi Download ImageBuilder (Dinamis OpenWrt/ImmortalWrt)
download_imagebuilder() {
    cd "${make_path}"
    echo -e "${STEPS} Downloading ImageBuilder for ${RELEASES_BRANCH}..."

    # Pisahkan Source dan Branch (Contoh: openwrt:25.12.1)
    local op_source=$(echo "${RELEASES_BRANCH}" | cut -d':' -f1)
    local op_branch=$(echo "${RELEASES_BRANCH}" | cut -d':' -f2)

    # Tentukan URL berdasarkan Source
    if [[ "${op_source}" == "immortalwrt" ]]; then
        local download_url="downloads.immortalwrt.org"
    else
        local download_url="downloads.openwrt.org"
    fi

    # Deteksi Ekstensi (25.12 ke atas pakai .zst, versi lama pakai .xz)
    if [[ "$op_branch" == 25* ]]; then
        local ext="tar.zst"
    else
        local ext="tar.xz"
    fi

    # URL Absolut untuk ARMSr/ARMv8
    local download_file="https://${download_url}/releases/${op_branch}/targets/armsr/armv8/${op_source}-imagebuilder-${op_branch}-armsr-armv8.Linux-x86_64.${ext}"

    echo -e "${INFO} URL: ${download_file}"
    curl -fsSOL "${download_file}" || error_msg "Gagal download ImageBuilder!"

    # Ekstrak (Mendukung Zstd atau XZ)
    if [[ "$ext" == "tar.zst" ]]; then
        zstd -d *.tar.zst -c | tar -x -C . --strip-components=0
    else
        tar -xJf *.tar.xz -C . --strip-components=0
    fi

    # Rapikan folder
    mv -f *-imagebuilder-* "${openwrt_dir}"
    rm -f *.tar.*
    
    echo -e "${SUCCESS} ImageBuilder siap di [ ${imagebuilder_path} ]"
}

# 3. Fungsi Custom Files & Fix Permissions (Krusial untuk S905X)
custom_files() {
    cd "${imagebuilder_path}"
    if [[ -d "${custom_files_path}" ]]; then
        echo -e "${STEPS} Memproses File Kustom & Mengatur Izin (Root:0755)..."
        mkdir -p files
        cp -rf "${custom_files_path}/." files/

        # Paksa semua file sistem inti menjadi 0755 agar tidak bootloop
        sudo chown -R 0:0 files/
        find files/ -type d -exec chmod 755 {} +
        find files/ -type f -exec chmod 644 {} +
        # Binary & Script Init wajib executable
        for d in "bin" "sbin" "usr/bin" "usr/sbin" "etc/init.d" "etc/uci-defaults"; do
            [ -d "files/$d" ] && find "files/$d" -type f -exec chmod 755 {} +
        done
        echo -e "${SUCCESS} Izin file berhasil disetel."
    fi
}

# 4. Fungsi Rebuild Firmware (Optimal untuk STB & APK Manager)
rebuild_firmware() {
    cd "${imagebuilder_path}"
    echo -e "${STEPS} Membangun Rootfs (Size: 1024MB)..."

    # Daftar Paket Terpadu (Menghindari konflik WPAD pada APK System)
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
        luci-app-ttyd luci-theme-material iw netdata vnstat2 vnstati2 nano \
        php8-cli php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv \
        php8-mod-mbstring"
        
    # Jalankan make dengan FORCE_UNSAFE_CONFIGURE=1 karena berjalan di LVM/Sudo
    # CONFIG_TARGET_ROOTFS_PARTSIZE diset 700MB agar muat paket berat
    make image PROFILE="generic" \
               PACKAGES="${my_packages}" \
               FILES="files" \
               V=s \
               FORCE_UNSAFE_CONFIGURE=1 \
               CONFIG_TARGET_ROOTFS_PARTSIZE=1024

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS} Build Berhasil!"
        mkdir -p "${output_path}"
        # Copy hasil build ARMSr ke folder output (tar.zst)
        cp bin/targets/armsr/armv8/*.tar.* "${output_path}/" 2>/dev/null || true
    else
        error_msg "Build Gagal!"
    fi
}

# --- EKSEKUSI URUTAN ---
download_imagebuilder
custom_files
rebuild_firmware
