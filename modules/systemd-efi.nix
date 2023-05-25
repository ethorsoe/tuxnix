{ config, pkgs, lib, ... }:
{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
  };
  systemd.services.update-boot-rndseed = {
    description = "Update random seed on ESP.";
    serviceConfig.ExecStart = "${pkgs.systemd}/bin/bootctl --no-variables random-seed";
    startAt = "hourly";
    wantedBy = [ "multi-user.target" ];
  };
}
