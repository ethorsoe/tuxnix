{ config, pkgs, lib, ... }: {
  options.tuxnix.metaBackup = lib.mkOption {
    description = "meta backup label and device";
    type = with lib.types; attrsOf str;
  };
  imports = [ ./backup-btrfs.nix ];
  config =
    let
      inplaceCopy = pkgs.rustPlatform.buildRustPackage {
        name = "inplace-copy";
        src = pkgs.fetchFromGitHub {
          owner = "ethorsoe";
          repo = "inplace-copy";
          rev = "6d1dcd20450ce18e025f0530a7ba75ca8222f695";
          sha256 = "sha256-mGzxv/WwtjekkKKm4v4f37g5/oKh3Bc8BIxXMO+jKro=";
        };
        cargoHash = "sha256-RW2uanyQGzV33snLIOQx6wOW6e6fl+NkB97eDQK7KPQ=";
      };
      mkMetaBackupService = name: device: {
        name = "meta-backup-${name}";
        value = {
          description = "Snapshot block device service";
          path = with pkgs;
            [ inplaceCopy ];
          script = ''
            set -eux
            mb="/mnt/pool/meta-backup"
            mkdir -p "$mb/${name}"
            if ! [[ -f "$mb/${name}/backup.img" ]]; then
              dd if="${device}" of="$mb/${name}/backup.img" iflag=direct oflag=direct bs=4M
              cat "$mb/${name}/backup.img" | sha256sum > "$mb/${name}/backup.img.sha256"
            fi
            cp --reflink=always "$mb/${name}/backup.img" "$mb/${name}/new-backup.img"
            inplace-copy "${device}" "$mb/${name}/new-backup.img"
            cat "$mb/${name}/new-backup.img" | sha256sum > "$mb/${name}/new-backup.img.sha256"
            if [[ "$(<"$mb/${name}/backup.img.sha256")" != \
                "$(<"$mb/${name}/new-backup.img.sha256")" ]] && \
                [[ "$(dd "if=${device}" iflag=direct bs=4M | sha256sum)" == \
                "$(<"$mb/${name}/new-backup.img.sha256")" ]]; then
              mv "$mb/${name}/new-backup.img.sha256" "$mb/${name}/backup.img.sha256"
              mv "$mb/${name}/new-backup.img" "$mb/${name}/backup.img"
            else
              rm "$mb/${name}/new-backup.img" "$mb/${name}/new-backup.img.sha256"
            fi
          '';
          serviceConfig.Type = "oneshot";
        };
      };
      mkMetaBackupTimer = name: _: {
        name = "meta-backup-${name}";
        value = {
          description = "Snapshot btrfs filesystem hourly timer";
          wantedBy = [ "multi-user.target" ];
          timerConfig = {
            OnActiveSec = 1800;
            OnUnitActiveSec = 14400;
            Unit = "meta-backup-${name}.service";
          };
        };
      };
    in
    {
      systemd.services = lib.mapAttrs' mkMetaBackupService config.tuxnix.metaBackup;
      systemd.timers = lib.mapAttrs' mkMetaBackupTimer config.tuxnix.metaBackup;
    };
}
