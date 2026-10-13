# features/zsh.nix
{...}: {
  flake.homeModules.zsh = {
    config,
    lib,
    pkgs,
    ...
  }: let
    p10kConfig = ./p10k.zsh;
    hasP10kConfig = builtins.pathExists p10kConfig;
  in {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh"; # older HM wants ".config/zsh"
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;

      history = {
        path = "${config.xdg.dataHome}/zsh/history";
        size = 50000;
        save = 50000;
        share = true;
        extended = true;
        ignoreAllDups = true;
        ignoreSpace = true;
      };

      envExtra = ''
        . "$HOME/.local/bin/env"
      '';

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];

      initContent = lib.mkMerge [
        (lib.mkOrder 500 ''
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')
        ''
          bindkey -e

          ${lib.optionalString hasP10kConfig "source ${p10kConfig}"}

          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
          zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'

          bindkey '^[[1;5C' forward-word
        ''
      ];
    };

    programs.zoxide.enableZshIntegration = true;
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = false; # don't clash with fzf.fish
    };

    programs.carapace = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = false;
    };
  };
}
