{
  inputs,
  moduleWithSystem,
  ...
}: {
  # Install this flake's configured Yazi package through Home Manager.
  flake.homeModules.yazi = moduleWithSystem (
    {self', ...}: {
      home.packages = [
        self'.packages.yazi
      ];
    }
  );

  # Build a Yazi package with its configuration embedded.
  perSystem = {pkgs, ...}: {
    packages.yazi = inputs.wrappers.lib.wrapPackage (
      {
        config,
        wlib,
        ...
      }: {
        # Capture pkgs from the outer perSystem function.
        # Do not request pkgs as an inner module argument, as that
        # would create the same recursion we encountered with Lazygit.
        inherit pkgs;

        imports = [
          wlib.wrapperModules.yazi
        ];

        settings.yazi = {
          mgr = {
            show_hidden = true;
            linemode = "ls_l";

            # Keep Yazi's normal three-column layout.
            # ratio = [ 0 1 0 ];
          };
        };

        # The current Yazi wrapper does not provide a dedicated
        # init.lua option, so add it to the generated config directory.
        constructFiles.initLua = {
          relPath = "${config.binName}-config/init.lua";

          content = ''
            function Linemode:ls_l()
              -- Fetch permissions natively using the :perm() function.
              local perm_str = self._file.cha:perm() or "---------"

              -- Fetch human-readable size and strip internal spacing.
              local size = self._file:size()
              local size_str = size and ya.readable_size(size):gsub(" ", "") or "-"

              -- Right-align the size to seven characters.
              local size_padded = string.format("%7s", size_str)

              -- Fetch modification time, formatted similarly to ls -l.
              local time = math.floor(self._file.cha.mtime or 0)
              local time_str = ""

              if time > 0 then
                time_str = os.date("%b %d %H:%M", time)
              end

              -- Combine permissions, size and modification time.
              return ui.Line(
                string.format(
                  " %s %s %s ",
                  perm_str,
                  size_padded,
                  time_str
                )
              )
            end
          '';
        };
      }
    );
  };
}
