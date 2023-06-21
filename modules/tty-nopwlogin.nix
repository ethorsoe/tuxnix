{ config, pkgs, lib, ... }: {
  security.pam.services.login.text =
    let
      ttys = "/dev/tty1:/dev/ttyAMA0:/dev/ttyS0";
    in
    lib.mkDefault (lib.mkBefore ''
      auth sufficient ${pkgs.linux-pam}/lib/security/pam_succeed_if.so debug tty in ${ttys}
    '');
  # workaround no root login assertion
  users.users."root".openssh.authorizedKeys.keys = [ "" ];
}
