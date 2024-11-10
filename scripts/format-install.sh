#!/usr/bin/env bash

set -eux
nixsubvol="$1"
hostname="$2"
disk="$3"
shift 3

partitionDisk() {
	dd if=/dev/zero "of=${disk}" bs=1M count=1
	local size=$(blockdev --getsize64 "$disk") blocksize=$(blockdev --getss "$disk")
	local tail=$(( size % 2**29 > 400 * 2**20 ? size % 2**29 : size % 2**29  + 2**29 ))
	local bootStart=$(( (size - tail) / blocksize ))
	fdiskCommands=(g n 1 2048 "$((bootStart - 1))" n 2 "$bootStart" "" t 2 1)
	printf '%s\n' "${fdiskCommands[@]}" w | fdisk --wipe always --wipe-partitions always "$disk"
	bootfs="$(fdisk -l "$disk" | grep -o "^${disk}[^ ]*2")"
	rootfs="$(fdisk -l "$disk" | grep -o "^${disk}[^ ]*1")"
	mkdosfs "$bootfs"
	mkfs.btrfs -m single -O no-holes "$rootfs"
}
partitionDisk
tuxnix-mount-installer "$nixsubvol" "$hostname" "$bootfs" "$rootfs" "$@"
