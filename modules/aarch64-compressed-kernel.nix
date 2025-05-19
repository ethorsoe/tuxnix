{ lib, pkgs, ... }: {
  boot.kernelPatches = [
    {
      name = "config-zboot-zstd";
      patch = null;
      extraStructuredConfig = { EFI_ZBOOT = lib.kernel.yes; KERNEL_ZSTD = lib.kernel.yes; };
    }
  ];
  nixpkgs.hostPlatform = lib.recursiveUpdate
    (lib.systems.elaborate lib.systems.examples.aarch64-multiplatform)
    {
      linux-kernel.target = "vmlinuz.efi";
      linux-kernel.installTarget = "zinstall";
    };
}
