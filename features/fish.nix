# features/fish.nix — fish only
{...}: {
  flake.homeModules.fish = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.tnxhm.shell;
  in {
    programs.fish = {
      enable = true;
      plugins = [
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
      ];

      shellAbbrs = cfg.abbreviations;

      shellInit = ''
        set -gx HOME (readlink -f $HOME)
      '';

      interactiveShellInit = ''
        set fish_greeting
        set -g fish_color_normal normal

        for cmd in ${lib.escapeShellArgs cfg.dumbTermWrapped}
            function $cmd
                env TERM=dumb command (status current-function) $argv
            end
        end

        fastfetch
        echo
      '';
    };

    programs.zoxide.enableFishIntegration = true;
  };
}
