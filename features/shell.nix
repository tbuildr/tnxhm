# features/shell.nix — settings shared by every shell
{...}: {
  flake.homeModules.shell = {lib, ...}: {
    options.tnxhm.shell = {
      abbreviations = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Abbreviations rendered for every shell (fish abbr, ble.sh sabbrev).";
      };
      dumbTermWrapped = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Commands always run with TERM=dumb.";
      };
    };

    config = {
      # Tools built on Charm's bubbletea/lipgloss/termenv that leak an OSC 11
      # background-color query reply (esp. short-lived calls, or glow -p's
      # raw-mode read picking up a stale reply inside devenv). Add new
      # offenders here as they turn up.
      tnxhm.shell.dumbTermWrapped = ["supabase" "gh" "glow"];

      home.shellAliases = {
        ls = "eza --icons --group-directories-first";
        ll = "eza -lah --icons --group-directories-first --git";
        la = "eza -a --icons --group-directories-first";
        lt = "eza --tree --icons --level=2";
        lgit = "lazygit";
        ldoc = "lazydocker";
        nc = "ncat";
        y = "yazi";
        bls = "/bin/ls";
        bvi = "/bin/vi";
        bat = "bat --paging=never";
        fastfetch = "command fastfetch";
        neofetch = "command fastfetch";
      };

      programs.zoxide.enable = true;
    };
  };
}
