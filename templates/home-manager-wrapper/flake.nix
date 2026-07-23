{
  description = "Home Manager configuration using tnxhm";

  inputs = {
    tnxhm.url = "github:tbuildr/tnxhm";

    nixpkgs.follows = "tnxhm/nixpkgs";
    home-manager.follows = "tnxhm/home-manager";
  };

  outputs = {
    nixpkgs,
    home-manager,
    tnxhm,
    ...
  }: let
    system = "x86_64-linux";

    # Change these values before activation.
    username = "YOUR_USERNAME";
    homeDirectory = "/var/home/YOUR_USERNAME";
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};

      modules = [
        # Public packages, programs and dotfiles.
        tnxhm.homeModules.default

        # Machine/user-specific profile.
        {
          home = {
            inherit username homeDirectory;
            stateVersion = "26.05";

            sessionVariables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
              DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
            };

            sessionPath = [
              "$HOME/.nix-profile/bin"
              "/nix/var/nix/profiles/default/bin"
              "$HOME/.local/bin"
            ];
          };

          programs.home-manager.enable = true;
        }
      ];
    };
  };
}
