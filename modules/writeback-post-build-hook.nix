{ pkgs, ... }:
{
  nix.settings.post-build-hook = pkgs.writeScript "writeback-post-build-hook" ''
    ${pkgs.systemd}/bin/systemd-run \
      -u "writeback-post-build-hook@$(systemd-escape "$DRV_PATH")" --no-block \
      --description="Initiate writeback on $DRV_PATH outputs" \
      find $OUT_PATHS "$DRV_PATH" -type f \
      -exec ${pkgs.libxfs.bin}/bin/xfs_io -r -c  'sync_range -w 0 0' '{}' +
  '';
}
