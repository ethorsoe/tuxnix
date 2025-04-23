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
      listInput = n: v:
        let
          path = lib.removePrefix "path:" v.url;
        in
        ''
          linkedPath="$(readlink -e ${path} || true)"
          if [[ -z "$linkedPath" ]]; then
            defaults+=(--override-input ${n} "path:$(readlink -f /etc/tuxnix/channels/${n})")
          elif [[ "${path}" != "$linkedPath" ]]; then
            defaults+=(--override-input ${n} "$linkedPath")
          fi
        '';
      listedInputs = lib.mapAttrsToList listInput filteredInputs;
      genTuxnixUpdateSystem = name: command: pkgs.writeScriptBin name ''
        #! ${pkgs.bash}/bin/bash -eux
        PATH+=":${lib.makeBinPath [ pkgs.nixos-rebuild pkgs.openssh ] }"
        switch=("''${@:-switch}")
        : ''${sudo=}
        defaults=()
        ! tty > /dev/null || defaults+=(-v)
        [[ "$UID" == 0 ]] || sudo=sudo
        flake="${config.tuxnix.update-system.selfFlakePath}"
        flake="$(readlink -e ''${flake%%/flake.nix}/flake.nix | sed 's|/flake.nix$||' || true)"
        flake="''${flake:-$(readlink -e /etc/tuxnix/channels/self)}"
        ${lib.concatStrings listedInputs}
        ${command}
      '';
      tuxnix-update-system = genTuxnixUpdateSystem "tuxnix-update-system" ''
        $sudo nixos-rebuild --flake "$flake" "''${defaults[@]}" \
          --no-write-lock-file "''${switch[@]}"
      '';
      tuxnix-install-system = genTuxnixUpdateSystem "tuxnix-install-system" ''
        $sudo nixos-install --flake "$flake#''${switch[-1]}"  "''${defaults[@]}" \
          --no-write-lock-file --no-root-password "''${switch[@]: 0: $((''${#switch[@]} - 1))}"
      '';
      tuxnix-mount-installer = pkgs.writeScriptBin "tuxnix-mount-installer"
        (builtins.readFile ../scripts/mount-install.sh);
      tuxnix-format-installer = pkgs.writeScriptBin "tuxnix-format-installer"
        (builtins.readFile ../scripts/format-install.sh);
    in
    {
      environment.systemPackages = [
        tuxnix-format-installer
        tuxnix-install-system
        tuxnix-mount-installer
        tuxnix-update-system
      ];
      nix.settings.fsync-store-paths =
        lib.mkIf (null != config.tuxnix.autoUpdate.target) true;
      systemd.services.tuxnix-auto-update = lib.mkIf (null != config.tuxnix.autoUpdate.target) {
        after = [ "network-online.target" ];
        description = "tuxnix automatic update service";
        serviceConfig.Type = "oneshot";
        path = [ tuxnix-update-system ];
        requires = [ "network-online.target" ];
        script = ''
          diff=$(( $(printf '%(%s)T') - $(stat -L -c %W /run/current-system) ))
          if (( diff < 24 * 60* 60 )); then
            echo "current-system only ''${diff}s old, skipping update"
            exit 0
          fi
          tuxnix-update-system ${config.tuxnix.autoUpdate.target}
        '';
        wantedBy = [ "multi-user.target" ];
      };
    };
}
