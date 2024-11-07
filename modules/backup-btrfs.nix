{ config, pkgs, lib, ... }: {
  options.tuxnix.backupBtrfs = lib.mkOption {
    description = "backup-btrfs config file options";
    type = with lib.types; attrsOf (attrsOf (oneOf [ int str ]));
  };
  config =
    let
      tlib = import ../lib.nix lib;
      backupBtrfs = pkgs.stdenv.mkDerivation {
        name = "backup-btrfs";
        buildInputs = with pkgs; [ btrfs-progs ];
        unpackPhase = "true";
        src = pkgs.fetchFromGitHub {
          owner = "ethorsoe";
          repo = "backup-btrfs";
          rev = "1148bcad677568dcc6fd4710628e417509a74632";
          sha256 = "sha256-BDW5gN3TtJpT1xBA64tMN2K/sxewvdieNaGt0PNQqGs=";
        };
        dontStrip = true;
        installPhase = ''
          mkdir -p $out/bin
          gcc -O2 -Wall -Wextra -std=c11 $src/btrfs-gen.c  -o $out/bin/btrfs-gen
          cp $src/backup-btrfs $src/sftp-upload $out/bin
        '';
      };
      mkConfig = name: params: pkgs.writeText "backup-btrfs-${name}.conf"
        (lib.generators.toKeyValue { } params);
      mkBackupBtrfsService = name: params: {
        name = "backup-btrfs-${name}";
        value = {
          description = "Snapshot btrfs filesystem service";
          path = with pkgs;
            [ bash backupBtrfs btrfs-progs lzop nettools openssh perl util-linux which xz zstd ];
          script = ''
            mkdir -p /mnt/persist/backup-btrfs
            ln -sf /mnt/persist/backup-btrfs /var/cache/
            backup-btrfs ${mkConfig name params}
          '';
          serviceConfig.Type = "oneshot";
        };
      };
      mkBackupBtrfsTimer = name: params: {
        name = "backup-btrfs-${name}";
        value = {
          description = "Snapshot btrfs filesystem hourly timer";
          wantedBy = [ "multi-user.target" ];
          timerConfig = {
            OnActiveSec = 600;
            OnUnitActiveSec = 3600;
            Unit = "backup-btrfs-${name}.service";
          };
        };
      };
    in
    {
      systemd.services = lib.mapAttrs' mkBackupBtrfsService config.tuxnix.backupBtrfs;
      systemd.timers = lib.mapAttrs' mkBackupBtrfsTimer config.tuxnix.backupBtrfs;
      system.activationScripts.backupBtrfs = "mkdir -p ${
      tlib.unwords (lib.attrsets.catAttrs "snapshotPath"
        (lib.attrsets.attrValues config.tuxnix.backupBtrfs))}";
    };
}
