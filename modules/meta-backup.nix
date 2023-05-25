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
        cargoSha256 = "sha256-RW2uanyQGzV33snLIOQx6wOW6e6fl+NkB97eDQK7KPQ=";
      };
      mkMetaBackupService = name: device: {
        name = "meta-backup-${name}";
        value = {
          description = "Snapshot block device service";
          path = with pkgs;
            [ inplaceCopy ];
          script = ''
            set -eux
            mkdir -p /mnt/pool/meta-backup/${name}
            if ! [[ -f "/mnt/pool/meta-backup/${name}/backup.img" ]]; then
              dd if="${device}" of="/mnt/pool/meta-backup/${name}/backup.img" iflag=direct oflag=direct bs=4M
              cat "/mnt/pool/meta-backup/${name}/backup.img" | sha256sum > "/mnt/pool/meta-backup/${name}/backup.img.sha256"
            fi
            cp --reflink=always "/mnt/pool/meta-backup/${name}/backup.img" "/mnt/pool/meta-backup/${name}/new-backup.img"
            inplace-copy "${device}" "/mnt/pool/meta-backup/${name}/new-backup.img"
            cat "/mnt/pool/meta-backup/${name}/new-backup.img" | sha256sum > "/mnt/pool/meta-backup/${name}/new-backup.img.sha256"
            if [[ "$(<"/mnt/pool/meta-backup/${name}/backup.img.sha256")" != "$(<"/mnt/pool/meta-backup/${name}/new-backup.img.sha256")" ]] &&
                [[ "$(dd "if=${device}" iflag=direct bs=4M | sha256sum)" == "$(<"/mnt/pool/meta-backup/${name}/new-backup.img.sha256")" ]]; then
              mv "/mnt/pool/meta-backup/${name}/new-backup.img.sha256" "/mnt/pool/meta-backup/${name}/backup.img.sha256"
              mv "/mnt/pool/meta-backup/${name}/new-backup.img" "/mnt/pool/meta-backup/${name}/backup.img"
            else
              rm "/mnt/pool/meta-backup/${name}/new-backup.img" "/mnt/pool/meta-backup/${name}/new-backup.img.sha256"
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
