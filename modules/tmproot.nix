{ config, pkgs, lib, ... }: {
  options.tuxnix = {
    bootUUID = lib.mkOption {
      example = "F4B4-3858";
      description = "UUID of boot filesystem";
      type = lib.types.uniq lib.types.str;
    };
    btrfsOpts = lib.mkOption {
      example = [ "autodefrag" ];
      default = [ "autodefrag" "compress=zstd" "noatime" "space_cache=v2" "nodev" "nosuid" ];
      description = "Btrfs general mount options.";
      type = lib.types.listOf lib.types.str;
    };
    fsUUID = lib.mkOption {
      example = "57846f19-3bf0-40cc-9aa7-aee77cbb3e4b";
      description = "UUID of main filesystem";
      type = lib.types.uniq lib.types.str;
    };
    nixSubvol = lib.mkOption {
      example = "nix2003";
      description = "btrfs subvolume on main fs for /nix";
      type = lib.types.uniq lib.types.str;
    };
  };
  imports = [ ./volatile-root.nix ];
  config = {
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" "nodev" "nosuid" ];
      neededForBoot = true;
    };
    fileSystems."/nix" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
      fsType = "btrfs";
      options = [ "subvol=${config.tuxnix.nixSubvol}" ] ++ config.tuxnix.btrfsOpts;
      neededForBoot = true;
    };
    fileSystems."/mnt/persist" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
      fsType = "btrfs";
      options = [ "subvol=/persist" ] ++ config.tuxnix.btrfsOpts;
      neededForBoot = true;
    };
    fileSystems."/var/log" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
      fsType = "btrfs";
      options = [ "subvol=/log" ] ++ config.tuxnix.btrfsOpts;
      neededForBoot = true;
    };
    fileSystems."/tmp" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
      fsType = "btrfs";
      options = [ "subvol=/tmp" ] ++ config.tuxnix.btrfsOpts;
    };
    fileSystems."/mnt/pool" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
      fsType = "btrfs";
      neededForBoot = true;
      options = config.tuxnix.btrfsOpts;
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/${config.tuxnix.bootUUID}";
      fsType = "vfat";
      options = [ "fmask=0077" ];
    };

    boot.initrd = {
      postDeviceCommands = ''
        sleep 2 && btrfs dev scan
        ${pkgs.btrfs-progs}/bin/btrfstune -n /dev/disk/by-uuid/${config.tuxnix.fsUUID}
        mkdir -p /tmp/testmount
        if mount /dev/disk/by-uuid/${config.tuxnix.fsUUID} /tmp/testmount; then
          umount /tmp/testmount
        else
          ${pkgs.btrfs-progs}/bin/btrfs rescue zero-log /dev/disk/by-uuid/${config.tuxnix.fsUUID}
        fi
      '';
      postMountCommands = ''
        ${pkgs.sqlite.bin}/bin/sqlite3 /mnt-root/nix/var/nix/db/db.sqlite vacuum
      '';
    };
    system.activationScripts.clear-profiles = lib.stringAfter
      (lib.optional (lib.versionOlder lib.trivial.release "23.11") "nix")
      ''
        ! [[ -d /mnt/pool/${config.tuxnix.nixSubvol}/var/nix/profiles/per-user ]] ||
          find /mnt/pool/${config.tuxnix.nixSubvol}/var/nix/profiles/per-user/ -type l -delete
        rm -f /mnt/pool/${config.tuxnix.nixSubvol}/var/nix/gcroots/profiles /root/.nix-channels
      '';
  };
}
