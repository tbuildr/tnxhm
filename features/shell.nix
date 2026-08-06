{self, ...}: {
  flake.homeModules.shell = {
    pkgs,
    config,
    lib,
    ...
  }: {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
      ];
      shellAliases = {
        ls = "eza --icons --group-directories-first";
        ll = "eza -lah --icons --group-directories-first --git";
        la = "eza -a --icons --group-directories-first";
        lt = "eza --tree --icons --level=2";
        lgit = "lazygit";
        ldoc = "lazydocker";
        y = "yazi";
        bls = "/bin/ls";
        bvi = "/bin/vi";
        bat = "bat --paging=never";
        fastfetch = "command fastfetch";
        neofetch = "command fastfetch";
      };
      shellInit = ''
        set -gx HOME (readlink -f $HOME)
      '';
      interactiveShellInit = ''
        set fish_greeting
        fastfetch
        echo
      '';
    };
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
