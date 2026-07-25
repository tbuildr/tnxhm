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

      functions = {
        __devenv_prompt_color = {
          body = ''
            if set -q IN_NIX_SHELL
                set -g tide_os_bg_color 0D2847
                set -g tide_pwd_bg_color 1E5A8E
                set -g tide_cmd_duration_bg_color 4A90D9
                set -g tide_time_bg_color D6E9F8
            else
                set -ge tide_os_bg_color
                set -ge tide_pwd_bg_color
                set -ge tide_cmd_duration_bg_color
                set -ge tide_time_bg_color
            end
          '';
          onVariable = "PWD";
        };
      };

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
        # Alias to run wrapped fastfetch function ahead of Bazzite /usr/bin/fastfetch
        fastfetch = "command fastfetch";
        neofetch = "command fastfetch";
      };

      interactiveShellInit = ''
        set fish_greeting

        fastfetch
        echo

        __devenv_prompt_color
      '';
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
