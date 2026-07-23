# Tom's Nix Home Manager configuration

## Overview

# tnxhm

My personal standalone Nix Home Manager configuration for Fedora Atomic and my
custom `tbzos` image.

The repository uses **flake-parts**, **import-tree**, and a feature-oriented
structure to manage my user environment while leaving operating-system
responsibilities with Fedora and the immutable host image.

# tnxhm

A reusable, feature-oriented Nix Home Manager configuration for Fedora Atomic
and other compatible Linux systems.

`tnxhm` provides the public and reusable part of a Home Manager environment. It
manages user applications, command-line tools, shell configuration, desktop
dotfiles and configured package wrappers while leaving personal identity and
host-specific values to a separate wrapper flake.

## Architecture

The configuration is divided into two repositories or layers:

```text
Public tnxhm
├── reusable Home Manager features
├── wrapped and configured packages
├── public dotfiles
├── flake applications
└── exports homeModules.default

User-specific wrapper
├── imports tnxhm.homeModules.default
├── defines username and home directory
├── defines a concrete homeConfigurations entry
├── adds personal Git identity and signing configuration
└── adds machine- or user-specific settings
```

The public repository does not need to know the username, home directory, Git
identity, signing-key path or private wrapper location.

The intended dependency direction is:

```text
private or local wrapper
        ↓ imports
public tnxhm
```

The public repository never imports or refers to a private repository.

## What this repository manages

The exported Home Manager module includes:

- Fish shell configuration;
- Starship prompt configuration for the host and Toolbx;
- Zoxide and Fzf integration;
- Neovim configured declaratively through NVF;
- native modular Niri configuration;
- Kitty configuration;
- desktop portal preferences;
- fonts and Fontconfig;
- an SSH agent and graphical askpass helper;
- a custom Fedora Toolbx image definition;
- Nix development and maintenance tools;
- general command-line applications;
- wrapped Btop, Lazygit, Fastfetch and Yazi packages.

The public configuration is exported as:

```nix
homeModules.default
```

It deliberately does not export a complete user profile such as:

```nix
homeConfigurations.tom
```

A small user-specific wrapper creates that final configuration.

## Repository structure

```text
.
├── configs/
│   └── fastfetch/
│       └── config.json
│
├── dotfiles/
│   ├── kitty/
│   │   └── kitty.conf
│   │
│   ├── niri/
│   │   ├── config.kdl
│   │   └── conf/
│   │       ├── animations.kdl
│   │       ├── autostart.kdl
│   │       ├── decorations.kdl
│   │       ├── environment.kdl
│   │       ├── environment.kdl.nvidia
│   │       ├── inputs.kdl
│   │       ├── keybinds.kdl
│   │       ├── monitors.kdl
│   │       ├── theme.kdl
│   │       └── windowrules.kdl
│   │
│   └── starship/
│       ├── starship.toml
│       └── starship-toolbox.toml
│
├── features/
│   ├── btop.nix
│   ├── cli-tools.nix
│   ├── devenv.nix
│   ├── editor.nix
│   ├── fastfetch.nix
│   ├── fonts.nix
│   ├── kitty.nix
│   ├── lazygit.nix
│   ├── niri.nix
│   ├── nix-tools.nix
│   ├── portals.nix
│   ├── shell.nix
│   ├── ssh.nix
│   ├── toolbox.nix
│   └── yazi.nix
│
├── flake-modules/
│   └── home-manager.nix
│
├── flake.lock
├── flake.nix
└── README.md
```

Every Nix file under `features/` is discovered automatically using
`import-tree`.

## Flake design

### flake-parts

The root `flake.nix` remains intentionally small. It defines the inputs,
supported systems and top-level flake-parts imports.

The main imports are:

```nix
inputs.home-manager.flakeModules.home-manager
./flake-modules/home-manager.nix
(inputs.import-tree ./features)
```

`flake-modules/home-manager.nix` combines the public features and exports them
as:

```nix
flake.homeModules.default
```

The user-specific wrapper selects the platform, creates `pkgs`, defines the
profile and constructs the final Home Manager configuration.

### Feature modules

Each feature is a flake-parts module and can define one or more of:

```nix
flake.homeModules
perSystem.packages
perSystem.apps
perSystem.formatter
```

A typical feature exports a reusable Home Manager module:

```nix
{
  flake.homeModules.example = {
    # Home Manager configuration
  };
}
```

Features that build configured packages expose them through `perSystem.packages`
and connect them to Home Manager using `moduleWithSystem`.

## Wrapped applications

Selected applications are built with their configuration embedded in the Nix
store using `nix-wrapper-modules`.

This provides an immutable, reproducible application configuration without
requiring a separate mutable configuration file under `~/.config`.

### Btop

The Btop wrapper includes settings such as:

- Vim-style navigation;
- true-colour output;
- rounded corners;
- terminal synchronisation;
- transparent background support;
- a two-second update interval.

Build it independently with:

```bash
nix build .#btop
./result/bin/btop
```

### Lazygit

The Lazygit wrapper generates an immutable YAML configuration and launches
Lazygit with that configuration.

It includes Nerd Font support and customised Git commands.

Build it independently with:

```bash
nix build .#lazygit
./result/bin/lazygit
```

Lazygit may still create writable runtime state, but its main configuration is
part of the wrapped package.

### Fastfetch

The Fastfetch wrapper reads:

```text
configs/fastfetch/config.json
```

Its configuration includes:

- Kitty image protocol support;
- Nerd Font icons;
- grouped system-information sections;
- percentage bars for memory and disk usage;
- JEDEC size formatting;
- a host-provided operating-system logo.

The logo path is:

```text
/usr/share/fastfetch/os-logo.png
```

This keeps branding outside Home Manager so different Fedora or bootc images can
provide their own logo.

Build it independently with:

```bash
nix build .#fastfetch
./result/bin/fastfetch
```

### Yazi

The Yazi wrapper embeds its TOML and Lua configuration and sets
`YAZI_CONFIG_HOME` to the immutable configuration directory.

The configuration includes:

- hidden-file display;
- the normal three-column layout;
- a custom detailed line mode;
- file permissions;
- human-readable sizes;
- modification timestamps.

Build it independently with:

```bash
nix build .#yazi
./result/bin/yazi
```

## Neovim through NVF

Neovim is configured declaratively with NVF in:

```text
features/editor.nix
```

The setup provides a LazyVim-inspired editor environment while remaining
represented in Nix.

Features include:

- Tokyo Night Moon theme;
- relative line numbers;
- persistent undo;
- Wayland clipboard integration;
- Blink completion;
- snippets;
- language-server support;
- formatting on save;
- Tree-sitter;
- Neo-tree;
- Telescope;
- Which-key;
- Bufferline;
- Lualine;
- Noice;
- Snacks notifications;
- Gitsigns;
- Diffview;
- Trouble;
- Toggleterm;
- integrated Lazygit;
- integrated Yazi.

Configured languages include Nix, Bash, Fish, C, C++, Lua, Markdown, JSON and
TOML.

The Tree-sitter CLI is included in the editor environment.

`vi`, `vim` and `nvim` resolve to the NVF-managed editor.

## Niri

Niri itself is supplied by the Fedora or bootc host rather than by Home Manager.

The configuration remains in native KDL so it can be compared directly with Niri
documentation and split naturally into separate files.

Home Manager recursively deploys:

```text
dotfiles/niri/
```

to:

```text
~/.config/niri/
```

The top-level `config.kdl` includes the files under `conf/`.

The configuration covers:

- input devices;
- British keyboard layout;
- animations;
- window decorations;
- environment variables;
- startup applications;
- keybindings;
- workspace and window behaviour;
- window rules;
- theme settings;
- optional monitor configuration.

An NVIDIA-specific environment file is retained as an alternative:

```text
dotfiles/niri/conf/environment.kdl.nvidia
```

The active Niri configuration is validated using the host’s Fedora Niri binary.

Run the validation app with:

```bash
nix run .#niri-validate
```

Home Manager also validates the KDL before activating a new generation.

## Fish and Starship

Fish is the primary interactive shell.

The public shell feature:

- disables the default Fish greeting;
- runs Fastfetch in interactive shells;
- configures general aliases;
- enables Starship;
- enables Zoxide;
- enables Fzf integration;
- loads Devenv integration;
- selects the appropriate Starship configuration.

The normal host prompt uses:

```text
~/.config/starship/starship.toml
```

Toolbx shells use:

```text
~/.config/starship/starship-toolbox.toml
```

Devenv projects may supply their own `STARSHIP_CONFIG`, which takes priority.

The selection order is:

```text
DEVENV_ROOT   project-specific prompt
TOOLBOX_PATH  Toolbx prompt
otherwise     normal host prompt
```

Personal abbreviations, signing-key filenames and wrapper-specific commands
belong in the user-specific wrapper rather than this public feature.

## Kitty

Kitty is supplied by the host operating system.

Home Manager deploys its public configuration to:

```text
~/.config/kitty/kitty.conf
```

The configured font is installed through the Home Manager fonts feature, with
Fontconfig enabled for the user environment.

Keeping the Kitty executable in the host image ensures that a terminal remains
available even if Nix or Home Manager needs repair.

## Toolbx and Podman

The Toolbx feature generates:

```text
~/.config/containers/toolbox.conf
~/.config/toolbox-image/Containerfile
~/.config/containers/systemd/toolbox-image.build
```

The exact image name may be adjusted in `features/toolbox.nix`.

The custom image is based on:

```text
registry.fedoraproject.org/fedora-toolbox:44
```

It installs a practical development environment including Fish, Git, Neovim,
Ripgrep, Fd, Fzf, Eza, Bat, Zoxide, Btop and Kitty terminal information.

The image creates:

```text
/nix -> /run/host/nix
```

Toolbx exposes the host filesystem under `/run/host`. This symlink makes the
host Nix store available at `/nix`, which allows Home Manager-generated links
and Nix-installed programs to work inside the container.

The feature exposes a build helper as both a package and a flake app:

```bash
nix build .#toolbox-image-build
nix run .#toolbox-image-build
```

The generated build uses Podman with a fresh base-image check and squashed
output.

Rebuilding the image affects newly created containers. Existing Toolbx
containers retain their existing writable container filesystem and must be
updated internally or recreated.

## SSH agent

The public SSH feature enables a user SSH agent and provides a graphical
`SSH_ASKPASS` helper through Zenity.

It does not include:

- private SSH keys;
- public-key identity selections;
- YubiKey credential filenames;
- Git signing configuration;
- PINs or passwords.

Those values belong in a private or local wrapper.

## Nix tooling

The Nix tooling feature includes utilities such as:

```text
alejandra
deadnix
nix-output-monitor
nix-tree
statix
```

It also enables:

- `nh`;
- Nix Index;
- Fish integration for Nix Index;
- the `comma` command.

Alejandra is exposed as the repository formatter:

```bash
nix fmt .
```

## CLI tools

The general CLI feature supplies applications such as:

```text
bat
eza
fd
lazydocker
rclone
ripgrep
tmux
wtype
```

Configured applications such as Btop, Lazygit, Fastfetch and Yazi are provided
by their dedicated wrapped-package features instead of the generic package list.

## Devenv

Devenv is enabled through its own feature.

Fish loads the Devenv hook after the normal interactive-shell setup. Trusted
projects can therefore enter their declarative environments automatically.

A project-specific `STARSHIP_CONFIG` is preserved when `DEVENV_ROOT` is set.

## Desktop portals

The portal feature deploys Niri-specific XDG portal preferences.

The configuration selects GTK for file-chooser functionality while retaining
appropriate GNOME implementations for other portal interfaces.

## Public and private configuration

A user-specific wrapper should contain settings such as:

```text
features/profile.nix
features/git.nix
features/personal-shell.nix
dotfiles/git/allowed_signers
```

Examples of settings that belong in the wrapper:

- `home.username`;
- `home.homeDirectory`;
- `home.stateVersion`;
- Git author name and email;
- Git signing-key paths;
- an SSH `allowed_signers` file;
- personal Fish abbreviations;
- private repository references;
- machine-specific environment values.

Do not put secrets in either repository.

Files that must remain outside ordinary Nix store-backed configuration include:

- private SSH keys;
- access tokens;
- API credentials;
- passwords;
- `rclone.conf` containing authentication tokens;
- YubiKey PINs;
- recovery codes.

## Installation

`tnxhm` is a reusable Home Manager module rather than a complete user
configuration.

Do not clone this repository directly over:

```text
~/.config/home-manager
```

Instead, create a small wrapper flake containing your username, home directory
and any private or machine-specific configuration.

The repository provides a template for creating that wrapper.

### Prerequisites

The host must already have:

- Nix with flakes enabled;
- Home Manager available for the initial activation;
- Git;
- the system-level applications listed under
  [Host dependencies](#host-dependencies).

On Fedora Atomic, the normal home path is:

```text
/var/home/USERNAME
```

On a conventional Linux installation, it is usually:

```text
/home/USERNAME
```

## Create a wrapper from the template

Create the Home Manager configuration directory:

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
```

Initialise it from the `tnxhm` wrapper template:

```bash
nix flake init \
  -t github:tbuildr/tnxhm#home-manager-wrapper
```

The template creates:

```text
~/.config/home-manager/
├── flake.nix
└── README.md
```

Open the generated flake:

```bash
vi flake.nix
```

Replace the template values:

```nix
username = "YOUR_USERNAME";
homeDirectory = "/var/home/YOUR_USERNAME";
```

For example:

```nix
username = "alice";
homeDirectory = "/var/home/alice";
```

On a conventional non-Atomic distribution, use:

```nix
homeDirectory = "/home/alice";
```

The generated wrapper imports:

```nix
tnxhm.homeModules.default
```

and adds the user-specific profile required to create:

```nix
homeConfigurations.${username}
```

## Initialise the wrapper repository

Nix flakes created inside Git repositories only include files that are tracked
or staged.

Initialise Git and stage the generated files:

```bash
git init -b main
git add flake.nix README.md
```

Create the lock file:

```bash
nix flake lock
git add flake.lock
```

The wrapper’s `flake.lock` pins an exact revision of `tnxhm` and all of its
inputs.

## Validate before activation

Inspect the wrapper outputs:

```bash
nix flake show
```

Validate the configuration:

```bash
nix flake check
```

Build the Home Manager generation without activating it:

```bash
home-manager build --flake .#YOUR_USERNAME
```

Replace `YOUR_USERNAME` with the username configured in `flake.nix`.

For example:

```bash
home-manager build --flake .#alice
```

## Initial activation

Activate the generated configuration:

```bash
home-manager switch --flake .#YOUR_USERNAME
```

For example:

```bash
home-manager switch --flake .#alice
```

The wrapper now combines:

```text
public tnxhm configuration
            +
user profile from the wrapper
            =
active Home Manager generation
```

After activation, `programs.home-manager.enable` makes the `home-manager`
command available through the user profile.

## Template contents

The supplied wrapper template provides a starting configuration equivalent to:

```nix
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
  }:
    let
      system = "x86_64-linux";

      username = "YOUR_USERNAME";
      homeDirectory = "/var/home/YOUR_USERNAME";
    in
    {
      homeConfigurations.${username} =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          modules = [
            tnxhm.homeModules.default

            {
              home = {
                inherit username homeDirectory;

                # Keep this at the version used for the first activation.
                stateVersion = "26.05";

                sessionPath = [
                  "$HOME/.nix-profile/bin"
                  "/nix/var/nix/profiles/default/bin"
                  "$HOME/.local/bin"
                ];

                sessionVariables = {
                  EDITOR = "nvim";
                  VISUAL = "nvim";
                  DOCKER_HOST =
                    "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
                };
              };

              programs.home-manager.enable = true;
            }
          ];
        };
    };
}
```

`home.stateVersion` is a compatibility baseline. Do not automatically change it
whenever Home Manager is updated.

## Creating a private wrapper repository

The generated wrapper can remain local, but storing it in a private Git
repository makes the complete configuration reproducible without exposing
personal values publicly.

The private wrapper is the appropriate place for:

- `home.username`;
- `home.homeDirectory`;
- personal Git name and email;
- SSH signing-key paths;
- `allowed_signers`;
- personal Fish abbreviations;
- machine-specific environment variables;
- private repository inputs.

Example private structure:

```text
~/.config/home-manager/
├── dotfiles/
│   └── git/
│       └── allowed_signers
├── features/
│   ├── git.nix
│   ├── personal-shell.nix
│   └── profile.nix
├── flake-modules/
│   └── home-manager.nix
├── flake.lock
└── flake.nix
```

The private assembly combines the modules with the public configuration:

```nix
modules = [
  inputs.tnxhm.homeModules.default

  config.flake.homeModules.profile
  config.flake.homeModules.git
  config.flake.homeModules.personal-shell
];
```

The dependency must always point in this direction:

```text
private wrapper
    └── imports public tnxhm
```

The public `tnxhm` repository must never import or reference the private
wrapper.

## Updating tnxhm

The wrapper continues using its pinned `tnxhm` revision until its lock file is
updated.

Update only the public `tnxhm` input:

```bash
cd ~/.config/home-manager

nix flake update tnxhm
nix flake check
home-manager switch --flake .#YOUR_USERNAME
```

Review the lock-file change:

```bash
git diff flake.lock
```

Then commit it:

```bash
git add flake.lock
git commit -m "Update tnxhm input"
git push
```

## Testing a local tnxhm checkout

Contributors can clone the public repository separately:

```bash
git clone \
  https://github.com/tbuildr/tnxhm \
  ~/.config/tnxhm
```

Test local, unpushed public changes while retaining the personal wrapper:

```bash
home-manager switch \
  --flake ~/.config/home-manager#YOUR_USERNAME \
  --override-input tnxhm \
  path:$HOME/.config/tnxhm
```

For example:

```bash
home-manager switch \
  --flake ~/.config/home-manager#alice \
  --override-input tnxhm \
  path:$HOME/.config/tnxhm
```

This temporarily combines:

```text
local ~/.config/tnxhm checkout
                +
existing personal wrapper
```

without changing the pinned GitHub revision in `flake.lock`.

## Testing the template locally

Before publishing template changes, initialise a temporary wrapper from the
local checkout:

```bash
test_directory=$(mktemp -d)

cd "$test_directory"

nix flake init \
  -t path:$HOME/.config/tnxhm#home-manager-wrapper
```

Inspect the generated files:

```bash
find "$test_directory" -maxdepth 2 -type f -print
```

Remove the test directory afterwards:

```bash
rm -rf "$test_directory"
```

## Manual integration without the template

An existing Home Manager flake can use `tnxhm` directly by adding it as an
input:

```nix
inputs = {
  tnxhm.url = "github:tbuildr/tnxhm";

  nixpkgs.follows = "tnxhm/nixpkgs";
  home-manager.follows = "tnxhm/home-manager";
};
```

Then import the public module into its Home Manager configuration:

```nix
modules = [
  tnxhm.homeModules.default

  {
    home.username = "example";
    home.homeDirectory = "/var/home/example";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
  }
];
```

The template is recommended for new installations because it provides this
wrapper structure automatically.

## Useful public-repository commands

Run these from the `tnxhm` checkout.

Validate the flake:

```bash
nix flake check
```

Inspect outputs:

```bash
nix flake show
```

Format Nix files:

```bash
nix fmt .
```

Build wrapped packages:

```bash
nix build .#btop
nix build .#lazygit
nix build .#fastfetch
nix build .#yazi
```

Run flake applications:

```bash
nix run .#niri-validate
nix run .#toolbox-image-build
```

Remove the temporary result link created by `nix build`:

```bash
rm -f result
```

## Host dependencies

The public configuration expects the host operating system to supply
system-level components such as:

- Nix and the Nix daemon;
- Niri and its session integration;
- Kitty;
- Noctalia;
- Fuzzel;
- Swaylock;
- Podman;
- Toolbx;
- graphical drivers;
- desktop and hardware integration;
- the Fastfetch operating-system logo;
- any host scripts referenced by the Niri configuration.

On Fedora Atomic or a custom bootc image, these components should be installed
in the host image rather than through Home Manager.

## Flake inputs

The main inputs are:

```text
nixpkgs
home-manager
flake-parts
import-tree
nix-index-database
NVF
nix-wrapper-modules
```

All inputs are pinned through `flake.lock`.

## Scope

This repository is designed primarily for Fedora Atomic and a Niri-based
desktop, but the exported module can be used as a starting point elsewhere.

It should be reviewed before activation because it includes opinionated package
choices, keybindings, shell behaviour, desktop configuration and assumptions
about host-provided software.
