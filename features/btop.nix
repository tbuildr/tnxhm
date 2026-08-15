{
  inputs,
  moduleWithSystem,
  ...
}: {
  # Reusable Home Manager module that installs this flake's
  # system-appropriate wrapped btop package.
  flake.homeModules.btop = moduleWithSystem (
    {self', ...}: {
      home.packages = [
        self'.packages.btop
      ];
    }
  );
  # Build a configured btop package for each system supported by this flake.
  perSystem = {pkgs, ...}: {
    packages.btop = inputs.wrappers.wrappers.btop.wrap {
      inherit pkgs;
      # Compile AMD GPU monitoring in (rocm_smi). Without this, gpu0
      # below just renders an empty box.
      package = pkgs.btop.override {
        rocmSupport = true;
      };
      settings = {
        color_theme = "Default";
        theme_background = false;
        truecolor = true;
        vim_keys = true;
        rounded_corners = true;
        terminal_sync = true;
        update_ms = 2000;
        proc_tree = false;

        # One gpuN box per physical GPU, 0-indexed. Add gpu1, gpu2...
        # if you add more cards later.
        shown_boxes = "cpu mem net proc gpu0";

        # Optional: poll GPU PCIe bandwidth too. Off upstream by default
        # (slight overhead) — drop this line if you don't want it.
        rsmi_measure_pcie_speeds = true;
      };
    };
  };
}
