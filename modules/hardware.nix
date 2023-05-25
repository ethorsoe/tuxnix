{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/all-hardware.nix") ];
  boot = {
    initrd.availableKernelModules =
      [
        "ahci"
        "mpt3sas"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "xhci_pci"
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];
  };
}
