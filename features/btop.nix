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

      settings = {
        color_theme = "Default";
        theme_background = false;
        truecolor = true;

        vim_keys = true;
        rounded_corners = true;
        terminal_sync = true;

        update_ms = 2000;
        proc_tree = false;
      };
    };
  };
}
