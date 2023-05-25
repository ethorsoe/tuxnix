lib:
(lib // rec {
  splitString = reg: s: builtins.filter (x: builtins.isString x && "" != x)
    (builtins.split reg s);
  lines = splitString "\n";
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
})
