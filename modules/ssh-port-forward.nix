{ config, pkgs, lib, ... }: {
  options.tuxnix.sshPortForward = {
    port = lib.mkOption {
      description = "Port on remote host to be forwarded.";
      type = lib.types.int;
    };
    username = lib.mkOption {
      description = "Remote host username.";
      type = lib.types.str;
    };
  };
  config.systemd.services.port-forward = {
    after = [ "network-online.target" ];
    description = "Port forward service";
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.openssh}/bin/ssh -i \${CREDENTIALS_DIRECTORY}/key" +
        " -N -R ${builtins.toString config.tuxnix.sshPortForward.port}:localhost:22" +
        " ${config.tuxnix.sshPortForward.username}@lohtuchai.dy.fi";
      LoadCredential = "key:/mnt/persist/user-ssh/id_ed25519-root";
      Restart = "always";
      RestartSec = 120;
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
  };
}
