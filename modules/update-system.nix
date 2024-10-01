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
      genTuxnixUpdateSystem = name: command: pkgs.writeScriptBin name ''
        #! ${pkgs.bash}/bin/bash -eux
        PATH+=":${lib.makeBinPath [ pkgs.nixos-rebuild ] }"
        switch=("''${@:-switch}")
        : ''${sudo=} ''${defaults=}
        [[ "$UID" == 0 ]] || sudo=sudo
        flake="${config.tuxnix.update-system.selfFlakePath}"
        flake="$(readlink -e ''${flake%%/flake.nix}/flake.nix | sed 's|/flake.nix$||' || true)"
        flake="''${flake:-$(readlink -e /etc/tuxnix/channels/self)}"
        ${lib.concatStrings listedInputs}
        ${command}
      '';
      tuxnix-update-system = genTuxnixUpdateSystem "tuxnix-update-system" ''
        $sudo nixos-rebuild -v --flake "$flake" $defaults --no-write-lock-file "''${switch[@]}"
      '';
      tuxnix-install-system = genTuxnixUpdateSystem "tuxnix-install-system" ''
        $sudo nixos-install -v --flake "$flake#''${switch[-1]}" $defaults --no-write-lock-file \
          --no-root-password "''${switch[@]: 0: $((''${#switch[@]} - 1))}"
      '';
      tuxnix-installer = pkgs.writeScriptBin "tuxnix-installer"
        (builtins.readFile ../scripts/install.sh);
    in
    {
      environment.systemPackages = [ tuxnix-install-system tuxnix-installer tuxnix-update-system ];
      nix.settings.sync-before-registering =
        lib.mkIf (null != config.tuxnix.autoUpdate.target) true;
      systemd.services.tuxnix-auto-update = lib.mkIf (null != config.tuxnix.autoUpdate.target) {
        after = [ "network-online.target" ];
        description = "tuxnix automatic update service";
        serviceConfig.Type = "oneshot";
        path = [ tuxnix-update-system ];
        requires = [ "network-online.target" ];
        script = ''
          tuxnix-update-system ${config.tuxnix.autoUpdate.target}
        '';
        wantedBy = [ "multi-user.target" ];
      };
    };
}
