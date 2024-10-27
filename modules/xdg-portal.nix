# Remember to export XDG_CURRENT_DESKTOP for d-bus environ
{ config, pkgs, lib, ... }: {
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    wlr.enable = true;
  };
}
