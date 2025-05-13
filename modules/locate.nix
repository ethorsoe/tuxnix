{ config, pkgs, lib, ... }:
let
  locateDir = "/mnt/persist/tuxnix-locate";
  tuxnixDB = "${locateDir}/db";
  locateUser = "tuxnix-locate";
in
{
  environment.systemPackages = [
    (pkgs.writeScriptBin "tuxnix-locate" ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.nix-index}/bin/nix-locate --db "${locateDir}" "$@"
    '')
  ];

  systemd = {
    services.update-tuxnix-locate = {
      description = "Update tuxnix-locate database";
      path = with pkgs; [ util-linux wget ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      script = ''
        set -eu
        shopt -s nullglob
        cd ${locateDir}
        project='https://github.com/nix-community/nix-index-database'
        wget -q -N "$project/releases/latest/download/index-x86_64-linux" || true
        ln -f index-x86_64-linux files
        if (( $(printf "%(%s)T") - $(stat -c %Y ${locateDir}/index-x86_64-linux) >
            (3600 * 24 * 15) )); then
          echo "Database not updated for 15 days." >&2
          exit 1
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = locateUser;
      };
      wantedBy = [ "multi-user.target" ];
      startAt = "hourly";
    };
    tmpfiles.rules = [
      "d ${locateDir} 0755 ${locateUser} root"
      "Z ${locateDir} 0755 ${locateUser} root"
    ];
  };
  users = {
    groups.tuxnix-locate = { };
    users.tuxnix-locate = {
      group = "tuxnix-locate";
      isSystemUser = true;
    };
  };
}
