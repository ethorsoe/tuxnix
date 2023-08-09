{
  description = "tuxnix NixOS configuration generator";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
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
          handleSetDeps = { handledSets ? { }, handledModules ? { }, passthrus ? [ ], inputs }:
            let
              hInputs = builtins.head inputs;
              isPassthru = !(builtins.isString hInputs);
              isSet = !isPassthru && lib.hasPrefix "set:" hInputs;
              isModule = !(isPassthru || isSet);
              name = lib.removePrefix "set:" hInputs;
              newHandledSets = handledSets // lib.optionalAttrs isSet { "${name}" = [ ]; };
              newHandledModules = handledModules // lib.optionalAttrs isModule {
                "${name}" = [ ];
              };
              passthruModule =
                if builtins.isAttrs hInputs ||
                  builtins.isFunction hInputs ||
                  builtins.isPath hInputs
                then hInputs
                else throw "Module type not recognized!";
              newPassthrus = passthrus
                ++ lib.optional isPassthru passthruModule
                ++ lib.optionals isModule (tlib.resolveModule effectiveModulesPaths name);
              newInputs = builtins.tail inputs
                ++ lib.optionals isSet (handledSets.${name} or sets.${name})
                ++ lib.optionals isModule (handledModules.${name} or [ name ]);
            in
            if [ ] == inputs
            then passthrus
            else
              handleSetDeps {
                handledSets = newHandledSets;
                handledModules = newHandledModules;
                passthrus = newPassthrus;
                inputs = newInputs;
              };
          instantiationconfig = inputattrs.instantiationdata.nixosConfig or { };
        in
        nixpkgs.lib.nixosSystem ({
          inherit system;
          modules = handleSetDeps
            {
              passthrus = [
                instantiationconfig
                {
                  environment.etc = nixpkgs.lib.mapAttrs'
                    (n: v: { name = "tuxnix/channels/${n}"; value = { source = v; }; })
                    allChannels;
                  nix.nixPath = [ "/etc/tuxnix/channels" ];
                }
                {
                  options.tuxnix.container.modulesPaths = lib.mkOption {
                    default = effectiveModulesPaths;
                    description = "Extra paths to load modules from.";
                    type = lib.types.listOf lib.types.path;
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
              ];
              inputs = modules;
            };
          specialArgs = { inputattrs = allChannels; };
        } // extraArgs);
    };
}
