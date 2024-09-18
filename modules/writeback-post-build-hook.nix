{ pkgs, ... }:
{
  nix.settings.post-build-hook = pkgs.writeScript "writeback-post-build-hook" ''
    find $OUT_PATHS "$DRV_PATH" -type f \
      -exec ${pkgs.libxfs.bin}/bin/xfs_io -r -c  'sync_range -w 0 0' '{}' +
  '';
}
