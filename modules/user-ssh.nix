{ config, lib, pkgs, ... }: {
  options.tuxnix.userSSHKeys = lib.mkOption {
    description = "Generate and link ssh keys to these users.";
    type = lib.types.attrsOf lib.types.bool;
  };

  config.system.activationScripts.genUsersED25519 =
    let
      tlib = import ../lib.nix lib;
      deps = [ "users" ] ++
        lib.optional (config.system.activationScripts ? genRootED25519) "genRootED25519";
      mapper = username: condition:
        let
          keyDir = "/mnt/persist/user-ssh";
          keyFile = "${keyDir}/id_ed25519-${username}";
          linkDir = "${config.users.users.${username}.home}/.ssh";
          linkFile = "${linkDir}/id_ed25519";
          chown = ''chown --no-dereference "${username}:${config.users.users.${username}.group}"'';
        in
        lib.optionalString condition ''
          if ! [[ -f "${keyFile}" ]]; then
            mkdir -p "${keyDir}"
            ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -b 4096 -N "" -f "${keyFile}" -q
            ${chown} "${keyFile}" "${keyFile}.pub"
          fi
          if ! [[ -e "${linkFile}" ]]; then
            if ! [[ -e "${linkDir}" ]]; then
              mkdir -p "${linkDir}"
              ${chown} "${linkDir}"
            fi
            ln -s "${keyFile}" "${linkFile}"
            ${chown} "${linkFile}"
          fi
        '';
    in
    lib.stringAfter deps (tlib.unlines (lib.mapAttrsToList mapper config.tuxnix.userSSHKeys));
}
