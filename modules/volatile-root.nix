{ config, pkgs, lib, ... }:
{
  config = {
    environment.etc."machine-id".source = "/mnt/persist/machine-id";
    users.mutableUsers = false;
    services.openssh.hostKeys = [
      { bits = 4096; path = "/mnt/persist/ssh/ssh_host_rsa_key"; type = "rsa"; }
      { path = "/mnt/persist/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
    ];
    system = {
      activationScripts.persist = ''
        if [[ -d /mnt/persist ]]; then
          mkdir -p /mnt/persist/ssh
        fi
        [[ -f "/mnt/persist/machine-id" ]] || \
          dd if=/dev/urandom count=1 2>/dev/null | md5sum | \
            ${pkgs.gnused}/bin/sed 's/ .*$//' > /mnt/persist/machine-id
      '';
    };
  };
}
