{
  imports = [ ./nix-sign-store.nix ];
  nix.sshServe.enable = true;
  services.openssh.extraConfig = ''
    Match User nix-ssh
      PasswordAuthentication no
    Match All
  '';
}
