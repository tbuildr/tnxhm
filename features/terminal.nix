{...}: {
  flake.homeModules.terminal = {
    xdg.configFile = {
      "fastfetch/config.jsonc".source =
        ../dotfiles/fastfetch/config.jsonc;

      "fastfetch/bazzite.png".source =
        ../dotfiles/fastfetch/bazzite.png;

      "kitty/kitty.conf".source =
        ../dotfiles/kitty/kitty.conf;
    };
  };
}
