{...}: {
  flake.homeModules.yazi = {
    xdg.configFile = {
      "yazi/init.lua".source =
        ../dotfiles/yazi/init.lua;

      "yazi/yazi.toml".source =
        ../dotfiles/yazi/yazi.toml;
    };
  };
}
