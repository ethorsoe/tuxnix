{
  description = "tuxnix NixOS configuration generator";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
  };

  outputs = { nixpkgs, self, ... }@flakeInputs:
    {
      tuxnixSystem = { inputattrs, system, modules, modulesPaths ? [ ], extraArgs ? { } }:
        let
          allChannels = flakeInputs // inputattrs;
          lib = nixpkgs.lib;
          tlib = import ./lib.nix lib;
          effectiveModulesPaths = [ ./modules ] ++ modulesPaths;
          foldModule = mods: newmod: mods ++
            (if builtins.isAttrs newmod || builtins.isFunction newmod || builtins.isPath newmod
            then [ newmod ]
            else if builtins.isString newmod
            then tlib.resolveModule effectiveModulesPaths newmod
            else throw "Module type not recognized!");
          instantiationconfig = lib.optionalAttrs (inputattrs ? instantiationdata)
            lib.importJSON
            (inputattrs.instantiationdata + "/config.json");
        in
        nixpkgs.lib.nixosSystem ({
          inherit system;
          modules = lib.foldl' foldModule [
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
          ]
            modules;
          specialArgs = { inputattrs = allChannels; };
        } // extraArgs);
    };
}
