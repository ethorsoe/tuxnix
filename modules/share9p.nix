{
  fileSystems."/mnt/share" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "nofail" "msize=16384" ];
  };
}
