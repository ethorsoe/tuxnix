{ lib, pkgs, ... }: {
  boot.kernelPatches = [
    {
      name = "config-zboot-zstd";
      patch = null;
      extraStructuredConfig = { EFI_ZBOOT = lib.kernel.yes; KERNEL_ZSTD = lib.kernel.yes; };
    }
    {
      name = "hexdump-from-nixos";
      patch = pkgs.substituteAll {
        src = ../lib/patches/zboot-hexdump-from-nixos.diff;
        hexdumpFromNixos = "${pkgs.util-linux}/bin/hexdump";
      };
    }
  ];
  nixpkgs.hostPlatform = {
    system = "aarch64-linux";
    linux-kernel = {
      name = "aarch64-multiplatform";
      baseConfig = "defconfig";
      DTB = true;
      autoModules = true;
      preferBuiltin = true;
      extraConfig = ''
        # Raspberry Pi 3 stuff. Not needed for   s >= 4.10.
        ARCH_BCM2835 y
        BCM2835_MBOX y
        BCM2835_WDT y
        RASPBERRYPI_FIRMWARE y
        RASPBERRYPI_POWER y
        SERIAL_8250_BCM2835AUX y
        SERIAL_8250_EXTENDED y
        SERIAL_8250_SHARE_IRQ y

        # Cavium ThunderX stuff.
        PCI_HOST_THUNDER_ECAM y

        # Nvidia Tegra stuff.
        PCI_TEGRA y

        # The default (=y) forces us to have the XHCI firmware available in initrd,
        # which our initrd builder can't currently do easily.
        USB_XHCI_TEGRA m
      '';
      target = "vmlinuz.efi";
      installTarget = "zinstall";
    };
    gcc = {
      arch = "armv8-a";
    };
  };
}
