{ pkgs, ... }:
let
  keyDir = "/mnt/persist/root-ssh";
  keyFile = "${keyDir}/id_ed25519";
in
{
  system.activationScripts.genRootED25519 = ''
    if ! [[ -f "${keyFile}" ]]; then
      mkdir -p "${keyDir}"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -b 4096 -N "" -f "${keyFile}" -q
    fi
  '';
  systemd.tmpfiles.rules = [
    "d /root/.ssh 0700 root root"
    "L /root/.ssh/id_ed25519 - - - - ${keyFile}"
  ];
}
