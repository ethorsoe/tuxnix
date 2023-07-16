{ config, lib, pkgs, ... }: {
  options.tuxnix.autoUpdate = {
    target = lib.mkOption {
      description = "nixos-rebuild operation to run automatic update with, null to disable";
      type = with lib.types; nullOr str;
      example = "switch";
      default = null;
    };
  };
  config =
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
        PATH+=":${lib.makeBinPath [ pkgs.nixos-rebuild ] }"
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
    {
      environment.systemPackages = [ tuxnix-update-system ];
      nix.settings.sync-before-registering =
        lib.mkIf (null != config.tuxnix.autoUpdate.target) true;
      systemd.services.tuxnix-auto-update = lib.mkIf (null != config.tuxnix.autoUpdate.target) {
        after = [ "network-online.target" ];
        description = "tuxnix automatic update service";
        serviceConfig.Type = "oneshot";
        path = [ tuxnix-update-system ];
        script = ''
          tuxnix-update-system ${config.tuxnix.autoUpdate.target}
        '';
        wantedBy = [ "multi-user.target" ];
      };
    };
}
