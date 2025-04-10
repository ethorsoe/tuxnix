{
  description = "tuxnix NixOS configuration generator";

  inputs = {
    nixpkgs.url = "file:///Please.provide.nixpkgs.as.input";
  };

  outputs = { nixpkgs, self, ... }@flakeInputs:
    {
      tuxnixSystem =
        { inputattrs
        , sets ? { }
        , system
        , modules
        , modulesPaths ? [ ]
        , extraArgs ? { }
        }:
        let
          allChannels = flakeInputs // inputattrs;
          lib = nixpkgs.lib;
          tlib = import ./lib.nix lib;
          effectiveModulesPaths = [ ./modules ] ++ modulesPaths;
          instantiationconfig = inputattrs.instantiationdata.nixosConfig or { };
        in
        lib.nixosSystem ({
          inherit system;
          modules = tlib.handleSetDeps
            {
              inherit sets;
              inputs = modules;
              modulesPaths = effectiveModulesPaths;
              passthrus = [
                instantiationconfig
                {
                  environment.etc = nixpkgs.lib.mapAttrs'
                    (n: v: { name = "tuxnix/channels/${n}"; value = { source = v; }; })
                    allChannels;
                  lib.tuxnix = tlib;
                  nix.nixPath = [ "/etc/tuxnix/channels" ];
                }
                {
                  options.tuxnix.container = {
                    modulesPaths = lib.mkOption {
                      default = effectiveModulesPaths;
                      description = "Extra paths to load modules from.";
                      type = lib.types.listOf lib.types.path;
                    };
                    sets = lib.mkOption {
                      default = sets;
                      description = "Sets defined for containers.";
                      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
                    };
                  };
                }
                {
                  options.tuxnix.update-system = {
                    selfFlakeFilePath = lib.mkOption {
                      default = inputattrs.self + "/flake.nix";
                      description = "Path of the flake.nix of top level flake";
                      type = lib.types.path;
                    };
                    selfFlakePath = lib.mkOption {
                      default = "./.";
                      description = "Path of the top level flake";
                      type = lib.types.str;
                    };
                  };
                }
                {
                  config.nix.registry = tlib.mapAttrs'
                    (n: v: {
                      name = builtins.replaceStrings [ "." ] [ "-" ] "t-${n}";
                      value = {
                        to = {
                          type = "path";
                          path = v;
                        };
                      };
                    })
                    allChannels //
                  { nixos.to = { type = "path"; path = nixpkgs; }; };
                }
              ];
            };
          specialArgs = { inputattrs = allChannels; };
        } // extraArgs);
    };
}
