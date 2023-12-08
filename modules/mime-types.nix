{ pkgs, ... }: {
  environment.systemPackages =
    let
      tuxnixMimeTypes = pkgs.runCommand "tuxnix-mime-types" { } ''
        mkdir -p $out/share/mime/packages
        cat > $out/share/mime/packages/tuxnix-mime-types.xml << TUXNIXEOF
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="text/x-nix">
            <comment>Nix source file</comment>
            <icon name="text-x-nix"/>
            <glob-deleteall/>
            <glob pattern="*.nix"/>
          </mime-type>
        </mime-info>
        TUXNIXEOF
      '';
    in
    [ tuxnixMimeTypes ];
}
