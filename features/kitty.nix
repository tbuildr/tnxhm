{...}: {
  flake.homeModules.kitty = {
    programs.kitty = {
      enable = true;

      # Continue using Fedora's /usr/bin/kitty.
      package = null;

      # Avoid introducing new Home Manager shell-integration behaviour.
      shellIntegration.mode = null;

      font = {
        # Already installed by features/fonts.nix.
        name = "MesloLGS Nerd Font Mono";
        size = 9;
      };

      settings = {
        # Disabled: kitty's config watcher recursively inotify-watches the
        # entire directory tree of any watched file (kovidgoyal/kitty#10102).
        # Since this config is symlinked via home-manager into /nix/store,
        # it was watching the whole store (~524k watches) and exhausting
        # fs.inotify.max_user_watches system-wide — which in turn broke
        # kind/containerd's own inotify use.
        # Fixed upstream in kitty PR #10105; re-enable once that lands in nixpkgs.
        # Reload manually instead: ctrl+shift+F5, or `kitty @ load-config`.
        auto_reload_config = "-1";
      };
    };
  };
}
