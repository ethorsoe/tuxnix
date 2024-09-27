{ pkgs, ... }:
{
  nix.settings.post-build-hook =
    let
      runWriteback = pkgs.writeScript "run-writeback-post-build-hook" ''
        #! ${pkgs.bash}/bin/bash
        set -eu
        set -o pipefail
        ${pkgs.findutils}/bin/find "$@" -type f -print0 | \
          ${pkgs.findutils}/bin/xargs -r -n 950 -0 \
          ${pkgs.libxfs.bin}/bin/xfs_io -r -c  'sync_range -w 0 0'
      '';
    in
    pkgs.writeScript "writeback-post-build-hook" ''
      ${pkgs.systemd}/bin/systemd-run \
        -u "writeback-post-build-hook@$(systemd-escape "$DRV_PATH")" --no-block \
        --description="Initiate writeback on $DRV_PATH outputs" \
        ${runWriteback} $OUT_PATHS "$DRV_PATH"
    '';
}
