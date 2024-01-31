{ config, pkgs, lib, ... }: {
  imports = [ ./assertions.nix ];
  services.paperless = {
    dataDir = "/mnt/persist/paperless";
    enable = true;
    mediaDir = "/mnt/persist/paperless/media";
  };
  tuxnix.users = {
    assertUids = [ config.services.paperless.user ];
  };
}
