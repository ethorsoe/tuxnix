lib:
(lib // rec {
  alphabet = "abcdefghijklmnopqrstuvwxyz";
  letterOfAlphabet = x: builtins.substring x 1 alphabet;
  splitString = reg: s: builtins.filter (x: builtins.isString x && "" != x)
    (builtins.split reg s);
  lines = splitString "\n";
  mapListToAttrs' = f: xs: builtins.listToAttrs (map f xs);
  mapListToAttrs = f: mapListToAttrs' (name: { inherit name; value = f name; });
  unlines = x: builtins.concatStringsSep "\n" x;
  words = splitString "[[:space:]]";
  unwords = x: builtins.concatStringsSep " " x;
  stripComment = x: builtins.head (builtins.split "#.*$" x);
  commentedFileToLines = path: builtins.filter
    (x: 0 != builtins.length (words x))
    (map stripComment (lines (builtins.readFile path)));
  matchPattern = pattern: data:
    builtins.head (builtins.elemAt (builtins.split pattern data) 1);
  resolveModule = modulesPaths: modName:
    let
      folder = olds: thisModPath:
        olds ++ (if builtins.pathExists (thisModPath + "/${modName}.nix")
        then [ (thisModPath + "/${modName}.nix") ]
        else [ ]);
      mods = builtins.foldl' folder [ ] modulesPaths;
    in
    if [ ] == mods then throw "Module ${modName} not found." else mods;
  handleSetDeps =
    { handledSets ? { }
    , handledModules ? { }
    , inputs
    , modulesPaths
    , passthrus ? [ ]
    , sets
    }:
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
        ++ lib.optionals isModule (resolveModule modulesPaths name);
      newInputs = builtins.tail inputs
        ++ lib.optionals isSet (handledSets.${name} or sets.${name})
        ++ lib.optionals isModule (handledModules.${name} or [ name ]);
    in
    if [ ] == inputs
    then passthrus
    else
      handleSetDeps {
        inherit modulesPaths sets;
        handledSets = newHandledSets;
        handledModules = newHandledModules;
        passthrus = newPassthrus;
        inputs = newInputs;
      };
})
