{ config, pkgs, lib, ... }: {
  security.pam.services.sudo.text =
    let
      so = "${pkgs.pam_ssh_agent_auth}/libexec/pam_ssh_agent_auth.so";
    in
    lib.mkDefault (lib.mkBefore "auth sufficient ${so} file=/etc/ssh/authorized_keys.d/%u");
  # workaround no root login assertion
  users.users."root".openssh.authorizedKeys.keys = [ "" ];
}
