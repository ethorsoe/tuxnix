{ config, lib, pkgs, ... }: {
  config.environment.systemPackages =
    let
      inputs = (import config.tuxnix.update-system.selfFlakeFilePath).inputs;
      filteredInputs = lib.filterAttrs (_: v: lib.hasPrefix "path:" v.url) inputs;
      listedInputs = lib.mapAttrsToList
        (n: v: ''
          if [[ -z "$(readlink -e ${lib.removePrefix "path:" v.url} || true)" ]]; then
            defaults+=" --override-input ${n} path:$(readlink -f /etc/tuxnix/channels/${n})"
          fi
        '')
        filteredInputs;
      tuxnix-update-system = pkgs.writeScriptBin "tuxnix-update-system" ''
        #! ${pkgs.bash}/bin/bash -eux
        switch=("''${@:-switch}")
        : ''${sudo=} ''${defaults=}
        [[ "$UID" == 0 ]] || sudo=sudo
        flake="${config.tuxnix.update-system.selfFlakePath}"
        flake="$(readlink -e ''${flake%%/flake.nix}/flake.nix | sed 's|/flake.nix$||' || true)"
        flake="''${flake:-$(readlink -e /etc/tuxnix/channels/self)}"
        ${lib.concatStrings listedInputs}
        $sudo nixos-rebuild --flake "$flake" $defaults --no-write-lock-file "''${switch[@]}"
      '';
    in
    [ tuxnix-update-system ];
}
