#!/bin/bash
set -e

# 1. Variabel Jalur
make_path="/builder"
openwrt_dir="openwrt_x86"
imagebuilder_path="${make_path}/${openwrt_dir}"
output_path="${GITHUB_WORKSPACE}/output"

# 2. Download ImageBuilder x86/64
download_ib_x86() {
    sudo mkdir -p "${make_path}"
    sudo chown runner:runner "${make_path}"
    cd "${make_path}"
    
    URL="https://downloads.openwrt.org"
    
    wget -qO- "$URL" | zstd -d | tar -x -C .
    mv openwrt-imagebuilder-* "${openwrt_dir}"
}

# 3. Build Process
build_x86() {
    cd "${imagebuilder_path}"
    
    # Kustomisasi Partisi untuk x86 (Penting: x86 butuh space lebih untuk Docker/PHP)
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=750" >> .config
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=64" >> .config

    # Paket spesifik x86 (tambahkan kmod-igc, kmod-e1000e untuk LAN modern)
    # Gunakan list paket Anda yang sebelumnya, tambahkan paket hardware x86
    my_packages="base-files ca-bundle dnsmasq-full dropbear e2fsprogs firewall4 fstools \
    kmod-button-hotplug kmod-nft-offload libc libgcc libustream-mbedtls logd \
    mkf2fs mtd netifd nftables odhcp6c odhcpd-ipv6only partx-utils ppp ppp-mod-pppoe procd-ujail \
    uci uclient-fetch urandom-seed urngd luci luci-compat luci-lib-base \
    luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full kmod-tcp-bbr \
    luci-mod-network kmod-mii luci-mod-status luci-mod-system luci-proto-3g luci-proto-mbim \
    mbim-utils picocom minicom luci-proto-ncm luci-proto-ppp luci-proto-qmi screen kmod-tun ttyd \
    libqmi libmbim glib2 ipset libcap libcap-bin ruby ruby-yaml kmod-inet-diag kmod-nft-tproxy \
    ip-full php8 haproxy tcpdump UDPspeeder irqbalance kmod-dummy bc uhttpd uhttpd-mod-ubus unzip \
    uqmi usb-modeswitch uuidgen zstd wwan ziptool zoneinfo-asia zoneinfo-core zram-swap bash \
    openssh-sftp-server adb wget-ssl httping htop jq tar coreutils-sleep coreutils-stat \
    kmod-nls-utf8 kmod-usb-storage cgi-io chattr comgt comgt-ncm coremark coreutils coreutils-base64 \
    coreutils-nohup luci-app-ttyd luci-theme-material wpad-openssl iw iwinfo wireless-regdb \
    fstrim"

    # Jalankan Build (x86 menggunakan PROFILE="generic")
    make image PROFILE="generic" \
               PACKAGES="${my_packages}" \
               FILES="${GITHUB_WORKSPACE}/files" \
               V=s

    # Pindahkan hasil (.img.gz dan .vmdk untuk Proxmox/VMware)
    mkdir -p "${output_path}"
    cp bin/targets/x86/64/*-generic-ext4-combined-efi.img.gz "${output_path}/"
    cp bin/targets/x86/64/*-combined-efi.vmdk "${output_path}/" 2>/dev/null || true
}

download_ib_x86
build_x86


