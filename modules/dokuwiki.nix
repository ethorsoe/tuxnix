{ config, pkgs, lib, ... }: {
  imports = [ ./assertions.nix ];
  options.tuxnix.services.dokuwiki = {
    sites = lib.mkOption {
      description = "values passed through to services.docuwiki.sites";
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
    webserver = lib.mkOption {
      description = "webserver value passed through to services.dokuwiki.webserver";
      type = lib.types.str;
    };
  };
  config = {
    services.dokuwiki = {
      webserver = config.tuxnix.services.dokuwiki.webserver;
      sites = lib.mapAttrs
        (n: v: {
          stateDir = "/mnt/persist/dokuwiki/${n}/data";
          usersFile = "/mnt/persist/dokuwiki/${n}/users.auth.php";
        } // v)
        config.tuxnix.services.dokuwiki.sites;
    };
    tuxnix.users = {
      assertUids = [ "dokuwiki" ];
      assertGids = [ config.services.${config.tuxnix.services.dokuwiki.webserver}.group ];
    };
  };
}
