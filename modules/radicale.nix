{ config, pkgs, lib, ... }: {
  imports = [ ./assertions.nix ];
  services.radicale = {
    settings.storage.filesystem_folder = "/mnt/persist/radicale/collections";
    enable = true;
  };
  tuxnix.users = {
    assertGids = [ "radicale" ];
    assertUids = [ "radicale" ];
  };
}
