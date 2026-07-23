{self, ...}: {
  flake.homeModules.terminal = {
    xdg.configFile = {
      "fastfetch/config.jsonc".source =
        self + /dotfiles/fastfetch/config.jsonc;

      "kitty/kitty.conf".source =
        self + /dotfiles/kitty/kitty.conf;
    };
  };
}
