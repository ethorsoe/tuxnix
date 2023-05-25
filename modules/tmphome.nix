{ config, pkgs, lib, ... }: {
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/${config.tuxnix.fsUUID}";
    fsType = "btrfs";
    options = [ "subvol=/home" ] ++ config.tuxnix.btrfsOpts;
  };
}
