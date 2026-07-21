{...}: {
  flake.homeModules.profile = {
    home = {
      username = "tom";
      homeDirectory = "/var/home/tom";
      stateVersion = "26.05";

      sessionPath = [
        "$HOME/.nix-profile/bin"
        "/nix/var/nix/profiles/default/bin"
        "$HOME/.local/bin"
      ];

      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
      };
    };

    programs.home-manager.enable = true;
  };
}
