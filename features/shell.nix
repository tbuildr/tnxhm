{...}: {
  flake.homeModules.shell = {
    xdg.configFile = {
      "starship/starship.toml".source =
        ../dotfiles/starship/starship.toml;

      "starship/starship-toolbox.toml".source =
        ../dotfiles/starship/starship-toolbox.toml;
    };

    programs.fish = {
      enable = true;

      shellInit = ''
        # Preserve STARSHIP_CONFIG supplied by devenv.
        # devenv exports its own STARSHIP_CONFIG before starting its fish subshell.
        if set -q DEVENV_ROOT
          # Preserve the project-specific devenv configuration.
        else if set -q TOOLBOX_PATH
          # Toolbox shells inherit the host value, so override it explicitly.
          set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship-toolbox.toml"
        else
          # Normal host shell.
          set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
        end
      '';

      shellAbbrs = {
        hms = "home-manager switch --flake ~/.config/home-manager#tom";
        ykadd = "ssh-add ~/.ssh/id_ed25519_sk_github_yk_1";
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

        # Override the stock Bazzite fastfetch alias.
        fastfetch = "/usr/bin/fastfetch";
        neofetch = "/usr/bin/fastfetch";
      };

      interactiveShellInit = ''
        set fish_greeting

        fastfetch
        echo
      '';
    };

    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        add_newline = false;
        aws.disabled = true;
      };
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
