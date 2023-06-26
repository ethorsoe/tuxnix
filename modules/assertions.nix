{ config, lib, ... }: {
  options.tuxnix.users = {
    assertUids = lib.mkOption {
      description = "Assert that these users have defined uids";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    assertGids = lib.mkOption {
      description = "Assert that these groups have defined gids";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config.assertions =
    map
      (n: {
        assertion = config.users.users.${n}.uid != null;
        message = "user ${n} uid not defined";
      })
      config.tuxnix.users.assertUids ++
    map
      (n: {
        assertion = config.users.groups.${n}.gid != null;
        message = "group ${n} gid not defined";
      })
      config.tuxnix.users.assertGids;
}
