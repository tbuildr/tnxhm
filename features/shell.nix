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
        set -g fish_color_normal normal

        # Tools built on Charm's bubbletea/lipgloss/termenv that leak an OSC 11
        # background-color query reply (esp. short-lived calls, or glow -p's
        # raw-mode read picking up a stale reply inside devenv). Add new
        # offenders here as they turn up.
        set -g dumb_term_wrapped supabase gh glow

        for cmd in $dumb_term_wrapped
            function $cmd
                env TERM=dumb command (status current-function) $argv
            end
        end

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
