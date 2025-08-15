{ config, lib, ... }: {
  options.tuxnix.oomd.swapUsedLimit = lib.mkOption {
    default = 80;
    description = "Set systemd-oomd SwapUsedLimit.";
    type = lib.types.int;
  };
  config = {
    systemd = {
      oomd = {
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
        extraConfig.SwapUsedLimit = "${toString config.tuxnix.oomd.swapUsedLimit}%";
      };
      services.systemd-oomd.after = [ "swap.target" ];
      slices = {
        "-".sliceConfig.ManagedOOMSwap = "kill";
        system.sliceConfig.ManagedOOMSwap = "kill";
        user.sliceConfig.ManagedOOMSwap = "kill";
      };
      user.units."slice" = {
        text = lib.mkForce ''
          [Slice]
          ManagedOOMMemoryPressure=kill
          ManagedOOMMemoryPressureLimit=80%
          ManagedOOMSwap=kill
        '';
        overrideStrategy = "asDropin";
      };
    };
  };
}
