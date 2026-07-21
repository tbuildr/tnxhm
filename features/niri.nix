{...}: {
  flake.homeModules.niri = {
    xdg.configFile."niri" = {
      source = ../dotfiles/niri;
      recursive = true;
    };
  };
}
