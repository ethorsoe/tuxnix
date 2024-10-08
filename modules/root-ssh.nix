# deprecation plan
# after 24.05 EOL add warning
# after 24.11 EOL remove module
{ lib, pkgs, ... }:
let
  oldKeyDir = "/mnt/persist/root-ssh";
  oldKeyFile = "${oldKeyDir}/id_ed25519";
  newKeyDir = "/mnt/persist/user-ssh";
  newKeyFile = "${newKeyDir}/id_ed25519-root";
in
{
  imports = [ ./user-ssh.nix ];
  config = {
    system.activationScripts.genRootED25519 = ''
      if ! [[ -f "${newKeyFile}" ]] && [[ -f ${oldKeyFile} ]]; then
        mkdir -p ${newKeyDir}
        mv ${oldKeyFile} ${newKeyFile}
        mv ${oldKeyFile}.pub ${newKeyFile}.pub
        [[ "$(readlink /root/.ssh/id_ed25519)" != ${oldKeyFile}  ]] || rm /root/.ssh/id_ed25519
        rmdir ${oldKeyDir}
      fi
    '';
    tuxnix.userSSHKeys.root = true;
  };
}
