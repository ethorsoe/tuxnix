{
  boot.initrd.postMountCommands = ''
    mkdir -p $targetRoot/mnt/persist
  '';
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      device = "nixstore";
      fsType = "9p";
      options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "nofail" "msize=16384" ];
      neededForBoot = true;
    };
  };
}
