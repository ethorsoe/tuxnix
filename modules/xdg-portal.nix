# you can enable pipewire support in chromium with
# enable-webrtc-pipewire-capturer in chrome://flags
{ config, pkgs, lib, ... }: {
  xdg.portal = {
    enable = true;
    gtkUsePortal = false;
    extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };
}
