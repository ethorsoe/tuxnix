{ config, pkgs, ... }:
let
  keyDir = "/mnt/persist/nix-sign-store";
in
{
  nix.settings.secret-key-files = "${keyDir}/priv-key.pem";
  system.activationScripts.genNixSignKeys = ''
    if ! [[ -f "${keyDir}/priv-key.pem" ]] ||
        ! [[ -f "${keyDir}/pub-key.pem" ]]; then
      mkdir -p "${keyDir}"
      ${pkgs.nix}/bin/nix-store \
        --generate-binary-cache-key "${config.networking.hostName}" \
        "${keyDir}/priv-key.pem" "${keyDir}/pub-key.pem"
    fi
  '';
}
