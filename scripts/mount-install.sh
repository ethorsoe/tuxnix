#!/usr/bin/env bash

set -eux
nixsubvol="$1"
hostname="$2"
bootfs="$3"
rootfs="$4"
shift 4

die() {
	echo "$*" >&2
	exit 1
}

cleanup() {
	if [[ -n "${mnt:-}" ]]; then
		for i in boot nix mnt/persist mnt/pool tmp; do
			umount ${mnt}/${i} || true
		done
		umount "$mnt"
	fi
	if [[ -n "${runDir:-}" ]]; then
		rm -rf -- "${runDir}"
	fi
}
trap cleanup EXIT

if [[ "btrfs" != "$(sudo blkid -s TYPE -o value "$rootfs")" ]]; then
	die "$rootfs not of type 'btrfs'" >&2
fi
if [[ "vfat" != "$(sudo blkid -s TYPE -o value "$bootfs")" ]]; then
	die "$bootfs not of type 'vfat'" >&2
fi

mkdir -p /run/tuxnix/tmp
runDir="$(mktemp --tmpdir=/run/tuxnix/tmp -d "install-nixvmhost-run.XXXXXXXXXX")"
mnt="${runDir}/mnt"
mkdir "$mnt"
chmod -R 755 "$runDir"
export TMPDIR="$runDir"

mountBtrfs() {
	mkdir -m 755 -p "${mnt}/${1}"
	mount -t btrfs -o "space_cache=v2,compress=zstd,autodefrag,noatime${2:+,subvol=$2}" \
		"$rootfs" "${mnt}/${1}"
}

sudo mount -t tmpfs -o mode=0755 none "$mnt"
mountBtrfs mnt/pool
sudo chmod 755 "${mnt}/mnt"
for creatsub in home persist log tmp "$nixsubvol"; do
	path="${mnt}/mnt/pool/${creatsub}"
	if [[ -d "$path" ]]; then continue; fi
	btrfs sub creat "$path"
done
sudo chmod 777 "${mnt}/mnt/pool/tmp"
sudo chmod +t "${mnt}/mnt/pool/tmp"
sudo mkdir -p "${mnt}/boot"
sudo mount -t vfat "$bootfs" "${mnt}/boot"
mountBtrfs nix "$nixsubvol"
mountBtrfs mnt/persist persist
mountBtrfs tmp tmp

mkdir "$runDir/instantiationdata"
cat > "$runDir/instantiationdata/flake.nix" << EOF
{
  description = "Instantiationdata";

  outputs = { ... }: {
    nixosConfig = {
      networking.hostName = "$hostname";
      tuxnix = {
        bootUUID = "$(sudo blkid -s UUID -o value "$bootfs")";
        fsUUID = "$(sudo blkid -s UUID -o value "$rootfs")";
        nixSubvol = "$nixsubvol";
      };
    };
  };
}
EOF
nixpkgs-fmt "$runDir/instantiationdata/flake.nix"

tuxnix-install-system --root "$mnt" --override-input instantiationdata "$runDir/instantiationdata" \
	"$@" "$hostname"
