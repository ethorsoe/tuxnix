{ config, pkgs, lib, ... }: {
  options.tuxnix.container = {
    configsDir = lib.mkOption {
      description = "Location of guest container configs.";
      type = lib.types.path;
    };
    containers = lib.mkOption {
      description = "tuxnix containers";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          autoStart = lib.mkOption {
            default = true;
            description = "Start this container automatically";
            type = lib.types.uniq lib.types.bool;
          };
          extraMounts = lib.mkOption {
            default = { };
            description = "Extra mounts from persist";
            type = lib.types.attrsOf lib.types.str;
          };
          hostBridge = lib.mkOption {
            example = "br0";
            description = "Bridge to be shared to the container";
            type = lib.types.uniq lib.types.str;
          };
          persistPath = lib.mkOption {
            example = "/mnt/persist/containers";
            default = "/mnt/persist/containers";
            description = "Directory containing persistent data for container.";
            type = lib.types.uniq lib.types.str;
          };
        };
      });
    };
  };
  config =
    let
      hostConfig = config;
      hostPkgs = pkgs;
      mkContainer = name: params: {
        inherit (params) autoStart;
        allowedDevices = [{
          modifier = "rwm";
          node = "/dev/net/tun";
        }];
        bindMounts = lib.mapAttrs'
          (mount: value: {
            name = "${mount}:idmap";
            value = {
              isReadOnly = false;
              hostPath = "${params.persistPath}/${name}/${value}";
            };
          })
          ({ "/mnt/persist" = "persist"; } // params.extraMounts);
        config = { config, pkgs, lib, ... }@configArgs:
          let
            containerConfig = import (hostConfig.tuxnix.container.configsDir + "/${name}.nix");
            baseConfig = containerConfig.config;
            effectiveBaseConfig =
              if builtins.isAttrs baseConfig
              then baseConfig
              else baseConfig configArgs;
            containerAutoConfig =
              assert !(effectiveBaseConfig ? imports);
              {
                imports = hostConfig.lib.tuxnix.handleSetDeps {
                  inherit (hostConfig.tuxnix.container) modulesPaths sets;
                  inputs = containerConfig.modules;
                };
                nixpkgs.pkgs = lib.mkDefault hostPkgs;
                boot.kernelPackages = hostConfig.boot.kernelPackages;
                environment.etc = {
                  machine-id.enable = false;
                } // lib.filterAttrs
                  (n: v: lib.hasPrefix "tuxnix/channels/" n)
                  hostConfig.environment.etc;
                lib.tuxnix = hostConfig.lib.tuxnix;
                networking.hostName = name;
                # workaround no root login assertion
                users.users."root".openssh.authorizedKeys.keys = [ "" ];
              };
          in
          lib.recursiveUpdate containerAutoConfig effectiveBaseConfig;
        extraFlags =
          let
            hashedName = builtins.hashString "sha256"
              "${config.networking.hostName}-tuxnix-container-${name}";
            containerUUID = lib.concatStringsSep "-" [
              (builtins.substring 0 8 hashedName)
              (builtins.substring 8 4 hashedName)
              (builtins.substring 12 4 hashedName)
              (builtins.substring 16 4 hashedName)
              (builtins.substring 20 12 hashedName)
            ];
          in
          [
            "--link-journal=host"
            "--private-users-ownership=map"
            "--private-users=pick"
            "--uuid=${containerUUID}"
          ];
        hostBridge = params.hostBridge;
        privateNetwork = true;
      };
      mkContActivation = name: params: {
        name = "tuxnixContainer${name}";
        value =
          ''
            mkdir -p ${params.persistPath}/${name}/persist
            chmod 755 ${params.persistPath}/${name}
          '';
      };
      mkRestart = name: params: {
        name = "container@${name}";
        value = {
          restartIfChanged = lib.mkForce false;
          stopIfChanged = lib.mkForce false;
          serviceConfig.TimeoutStopSec = 20;
          unitConfig.RequiresMountsFor = [ params.persistPath ];
        };
      };
    in
    {
      systemd.services = lib.mapAttrs' mkRestart config.tuxnix.container.containers;
      containers = lib.mapAttrs mkContainer config.tuxnix.container.containers;
      system.activationScripts = lib.mapAttrs' mkContActivation config.tuxnix.container.containers;
    };
}
