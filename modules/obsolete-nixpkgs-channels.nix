{ config, pkgs, lib, ... }: {
  environment.etc =
    let
      oldChans = {
        "nixos-20.09" = "sha256-tAMJnUwfaDEB2aa31jGcu7R7bzGELM9noc91L2PbVjg=";
        "nixos-21.05" = "sha256-lkA5X3VNMKirvA+SUzvEhfA7XquWLci+CGi505YFAIs=";
        "nixos-21.11" = "sha256-hekabNdTdgR/iLsgce5TGWmfIDZ86qjPhxDg/8TlzhE=";
        "nixos-22.05" = "sha256-Zffu01pONhs/pqH07cjlF10NnMDLok8ix5Uk4rhOnZQ=";
        "nixos-22.11" = "sha256-lHrKvEkCPTUO+7tPfjIcb7Trk6k31rz18vkyqmkeJfY=";
        "nixos-23.05" = "sha256-LWvKHp7kGxk/GEtlrGYV68qIvPHkU9iToomNFGagixU=";
        "nixos-23.11" = "sha256-zwVvxrdIzralnSbcpghA92tWu2DV2lwv89xZc8MTrbg=";
        "nixos-24.05" = "sha256-OnSAY7XDSx7CtDoqNh8jwVwh4xNL/2HaJxGjryLWzX8=";
      };
      getDir = n: v: {
        name = "tuxnix/channels/${n}";
        value.source = pkgs.fetchgit {
          rev = "refs/heads/${n}";
          sha256 = v;
          url = "https://github.com/NixOS/nixpkgs.git";
        };
      };
    in
    lib.mapAttrs' getDir oldChans;
}
