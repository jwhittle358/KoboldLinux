profile_kobold_linux() {
    profile_standard
    title="Kobold Linux"
    desc="Personal Linux Distro for Jackie Whittle"
    image_name="kobold_linux"
    kernel_cmdline="unionfs_size=512M console=tty0"
    apkovl="aports/scripts/genapkovl-kobold_linux.sh"
    apks="$apks alpine-base openssh sudo doas bash curl jq git vim rsync nftables tcpdump nmap bind-tools iproute2 iputils chrony ca-certificates openssl util-linux e2fsprogs dosfstools"
}
