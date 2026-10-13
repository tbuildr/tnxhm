# features/bash.nix — bash only
{...}: {
  flake.homeModules.bash = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.tnxhm.shell;

    sabbrevs =
      lib.concatStringsSep "\n"
      (lib.mapAttrsToList (n: v: "ble-sabbrev ${n}=${lib.escapeShellArg v}") cfg.abbreviations);

    dumbTermWrappers =
      lib.concatMapStringsSep "\n"
      (cmd: "${cmd}() { TERM=dumb command ${cmd} \"$@\"; }")
      cfg.dumbTermWrapped;

    # Nerd Font glyph from a hex codepoint, so no private-use chars live in this file
    i = code: builtins.fromJSON ''"\u${code}"'';

    arrow = i "e0b0"; # powerline separator
    roundL = i "e0b6"; # rounded start
    roundR = i "e0b4"; # rounded end
  in {
    programs.bash = {
      enable = true;
      enableCompletion = false; # Fedora's /etc/bashrc already loads bash-completion
      historyControl = ["ignoreboth" "erasedups"];
      historySize = 50000;
      historyFileSize = 50000;
      historyFile = "${config.xdg.dataHome}/bash/history";

      bashrcExtra = ''
        # Resolve /home -> /var/home, matching fish
        export HOME="$(readlink -f "$HOME")"

        # Carried over from Fedora's skeleton ~/.bashrc
        if [ -f /etc/bashrc ]; then
          . /etc/bashrc
        fi

        if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
          PATH="$HOME/.local/bin:$HOME/bin:$PATH"
        fi
        export PATH

        if [ -d ~/.bashrc.d ]; then
          for rc in ~/.bashrc.d/*; do
            [ -f "$rc" ] && . "$rc"
          done
        fi
        unset rc

        . "$HOME/.local/bin/env"
      '';

      profileExtra = ''
        # Resolve /home -> /var/home, matching fish (login shells read this before .bashrc)
        export HOME="$(readlink -f "$HOME")"

        . "$HOME/.local/bin/env"
      '';

      initExtra = lib.mkMerge [
        # ble.sh loads first, detached
        (lib.mkBefore ''
          [[ $- == *i* ]] && source ${pkgs.blesh}/share/blesh/ble.sh --attach=none
        '')

        ''
          ${dumbTermWrappers}

          fastfetch
          echo
        ''

        # ble-attach must run after every HM integration (zoxide lands after mkAfter)
        (lib.mkOrder 2500 ''
          if [[ ''${BLE_VERSION-} ]]; then
            ${sabbrevs}
            bleopt edit_magic_accept=sabbrev

            # Matrix-ish highlighting (256-colour indexes)
            ble-face command_builtin=fg=46
            ble-face command_builtin_dot=fg=46,bold
            ble-face command_alias=fg=48
            ble-face command_function=fg=40
            ble-face command_file=fg=34
            ble-face command_keyword=fg=118
            ble-face filename_directory=fg=28,underline
            ble-face auto_complete=fg=238

            # Transient prompt: erase line 1 (the bar) on Enter, keep the ❯ line
            bleopt prompt_ps1_transient=trim

            # Live clock on the right of the ❯ line, drawn natively by ble.sh
            bleopt prompt_rps1='\g{fg=46}\t\g{none}'

            ble-attach
          fi
        '')
      ];
    };

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = false; # leave fish's Ctrl+R as-is
    };
    programs.zoxide.enableBashIntegration = true;
    programs.carapace.enableBashIntegration = false; # breaks completion under ble.sh

    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = false;
      enableFishIntegration = false; # fish keeps Tide
      settings = {
        version = 3;
        final_space = true;

        # No network calls from the prompt
        upgrade = {
          auto = false;
          notice = false;
        };

        blocks = [
          # Line 1: powerline bar
          {
            type = "prompt";
            alignment = "left";
            segments = [
              {
                type = "session";
                style = "diamond";
                leading_diamond = roundL;
                background = "#003b00";
                foreground = "#00ff41";
                template = " {{ .UserName }} ";
              }
              {
                type = "path";
                style = "powerline";
                powerline_symbol = arrow;
                background = "#008f11";
                foreground = "#0d0208";
                template = " ${i "f07c"}  {{ .Path }} ";
                properties.style = "full";
              }
              {
                type = "git";
                style = "powerline";
                powerline_symbol = arrow;
                background = "#00ff41";
                background_templates = [
                  "{{ if or .Working.Changed .Staging.Changed }}#9aff00{{ end }}"
                  "{{ if or (gt .Ahead 0) (gt .Behind 0) }}#d4ff00{{ end }}"
                ];
                foreground = "#0d0208";
                template = " {{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  ${i "f044"} {{ .Working.String }}{{ end }}{{ if .Staging.Changed }}  ${i "f046"} {{ .Staging.String }}{{ end }} ";
                properties = {
                  fetch_status = true;
                  fetch_upstream_icon = true;
                  branch_icon = "";
                };
              }
              {
                type = "executiontime";
                style = "powerline";
                powerline_symbol = arrow;
                background = "#0d0208";
                foreground = "#00ff41";
                template = " ${i "f252"} {{ .FormattedMs }} ";
                properties = {
                  threshold = 0;
                  style = "austin";
                };
              }
              {
                type = "status";
                style = "diamond";
                trailing_diamond = roundR;
                background = "#003b00";
                background_templates = ["{{ if gt .Code 0 }}#8b0000{{ end }}"];
                foreground = "#00ff41";
                foreground_templates = ["{{ if gt .Code 0 }}#ff4141{{ end }}"];
                template = " {{ if gt .Code 0 }}${i "f00d"} {{ .Code }}{{ else }}${i "f256"}{{ end }} ";
                properties.always_enabled = true;
              }
            ];
          }

          # Line 2: input arrow (green on success, red on failure)
          {
            type = "prompt";
            alignment = "left";
            newline = true;
            segments = [
              {
                type = "text";
                style = "plain";
                foreground = "#00ff41";
                foreground_templates = ["{{ if gt .Code 0 }}#ff4141{{ end }}"];
                template = "❯";
              }
            ];
          }
        ];
      };
    };
  };
}
