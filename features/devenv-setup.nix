{...}: {
  flake.homeModules.devenv-setup = {
    pkgs,
    lib,
    ...
  }: {
    # Install the Devenv CLI for the user.
    home.packages = [
      pkgs.devenv
      pkgs.direnv
    ];

    # Global direnvrc: pulls in devenv's `use_devenv` function so any
    # project's .envrc can just say `use devenv` without repeating the
    # source_url boilerplate per-project.
    xdg.configFile."direnv/direnvrc".text = ''
      eval "$(devenv direnvrc)"
    '';

    # Automatically activate trusted Devenv projects.
    # Changed to call direnv which it's envrc will call devenv
    # This means that we can have .envrc in project subdirs to set variables specific to that
    # and hold that next to the project
    programs.fish.interactiveShellInit = lib.mkAfter ''
      direnv hook fish | source
    '';
  };
}
