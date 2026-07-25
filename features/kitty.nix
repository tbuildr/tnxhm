{...}: {
  flake.homeModules.kitty = {
    programs.kitty = {
      enable = true;

      # Continue using Fedora's /usr/bin/kitty.
      package = null;

      # Avoid introducing new Home Manager shell-integration behaviour.
      shellIntegration.mode = null;

      font = {
        # Already installed by features/fonts.nix.
        name = "MesloLGS Nerd Font Mono";
        size = 9;
      };
    };
  };
}
