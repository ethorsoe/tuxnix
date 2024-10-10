{ config, pkgs, lib, ... }: {
  options.tuxnix.nixLogsExpireTime = lib.mkOption {
    example = 90;
    default = 90;
    description = "Nix logs expire time in days.";
    type = lib.types.int;
  };
  config.systemd.services.prune-nix-logs = {
    serviceConfig = {
      ExecStart = "${pkgs.findutils}/bin/find /nix/var/log/nix/drvs/ -type f -mtime" +
        " +${builtins.toString config.tuxnix.nixLogsExpireTime} -delete";
      Type = "oneshot";
    };
    startAt = "monthly";
    wantedBy = [ "multi-user.target" ];
  };
}
