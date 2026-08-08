{...}: {
  flake.homeModules.theming = {
    gtk = {
      enable = true;

      theme.name = "adw-gtk3-dark";

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    home.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
    };
  };
}
