# Tom's Nix Home Manager configuration

## Overview

# tnxhm

My personal standalone Nix Home Manager configuration for Fedora Atomic and my
custom `tbzos` image.

The repository uses **flake-parts**, **import-tree**, and a feature-oriented
structure to manage my user environment while leaving operating-system
responsibilities with Fedora and the immutable host image.

## Overview

This configuration targets:

```text
Platform:       x86_64-linux
Home profile:   tom
Home directory: /var/home/tom
State version:  26.05
Host:           Fedora 44 Atomic / tbzos
```

It manages:

- user packages and command-line tools;
- Fish, Starship, Zoxide and Devenv integration;
- Neovim through NVF;
- wrapped and preconfigured applications;
- native modular Niri configuration;
- Kitty configuration;
- desktop portal preferences;
- a custom Fedora Toolbx image;
- an SSH agent and graphical YubiKey askpass helper;
- user environment variables and Home Manager activation.

This is a personal configuration. It contains usernames, paths, package choices,
commands and host assumptions specific to my system.

## Architecture

The configuration is divided into three layers:

```text
Fedora Atomic / tbzos
├── kernel, drivers and graphics stack
├── Niri and desktop session
├── Kitty and system applications
├── Podman and Toolbx
├── systemd system services
├── SELinux, PAM and hardware integration
└── immutable operating-system image

flake-parts
├── assembles flake outputs
├── automatically imports feature modules
├── builds configured application packages
├── exposes runnable apps
├── exposes the repository formatter
└── connects per-system packages to Home Manager

Home Manager
├── installs packages into the user profile
├── activates configuration files
├── configures Fish and Starship
├── manages user services
├── manages environment variables
└── provides generations and rollback
```

Home Manager is deliberately retained as the activation layer. Flake-parts
builds and organises the configuration, while Home Manager safely applies it to
the user environment.

## Repository structure

```text
.
├── configs
│   └── fastfetch
│       └── config.json
│
├── dotfiles
│   ├── kitty
│   │   └── kitty.conf
│   │
│   ├── niri
│   │   ├── config.kdl
│   │   └── conf
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
│   └── starship
│       ├── starship.toml
│       └── starship-toolbox.toml
│
├── features
│   ├── btop.nix
│   ├── cli-tools.nix
│   ├── devenv.nix
│   ├── editor.nix
│   ├── fastfetch.nix
│   ├── fonts.nix
│   ├── lazygit.nix
│   ├── niri.nix
│   ├── nix-tools.nix
│   ├── portals.nix
│   ├── profile.nix
│   ├── shell.nix
│   ├── ssh.nix
│   ├── terminal.nix
│   ├── toolbox.nix
│   └── yazi.nix
│
├── flake-modules
│   └── home-manager.nix
│
├── flake.lock
├── flake.nix
└── README.md
```

## Flake design

### flake-parts

`flake.nix` is intentionally small. It defines inputs, supported systems and the
top-level module imports.

The main imports are:

```nix
inputs.home-manager.flakeModules.home-manager
./flake-modules/home-manager.nix
(inputs.import-tree ./features)
```

`flake-modules/home-manager.nix` creates the `tom` standalone Home Manager
configuration and selects the reusable modules that belong to it.

### import-tree

Every `.nix` file under `features/` is a top-level flake-parts module and is
imported automatically by `import-tree`.

Each feature can define one or more of:

```nix
flake.homeModules
perSystem.packages
perSystem.apps
perSystem.formatter
```

This keeps features self-contained without maintaining a long list of file
imports in `flake.nix`.

### Feature modules

A typical feature exposes a reusable Home Manager module:

```nix
{
  flake.homeModules.example = {
    # Home Manager configuration
  };
}
```

Features that build configured packages use:

```nix
perSystem.packages
```

and connect those packages to Home Manager with:

```nix
moduleWithSystem
self'.packages
```

## Wrapped applications

The repository uses `nix-wrapper-modules` to build selected applications with
their configuration embedded in the Nix store.

This removes the need for mutable configuration files under `~/.config` for
those applications.

### Btop

`features/btop.nix` builds a configured Btop package with:

- Vim navigation keys;
- true colour;
- rounded corners;
- terminal synchronisation;
- a two-second update interval;
- transparent terminal background support.

Build it independently with:

```bash
nix build .#btop
./result/bin/btop
```

### Lazygit

`features/lazygit.nix` generates an immutable YAML configuration and launches
Lazygit with `--use-config-file`.

The configuration enables Nerd Font version 3 and adds custom pull commands,
including recursive submodule pulling.

Build it independently with:

```bash
nix build .#lazygit
./result/bin/lazygit
```

Lazygit may still maintain writable runtime state, but its main configuration is
embedded in the package.

### Fastfetch

`features/fastfetch.nix` reads:

```text
configs/fastfetch/config.json
```

and builds a wrapped Fastfetch package whose configuration is stored in the Nix
derivation.

The configuration includes:

- a host-provided operating-system logo;
- Kitty image protocol support;
- a Gruvbox-inspired colour palette;
- grouped login, hardware, network, peripheral, media and time sections;
- Nerd Font icons;
- percentage bars for memory and disk usage;
- JEDEC sizes.

The logo remains image-specific:

```text
/usr/share/fastfetch/os-logo.png
```

This allows the same Home Manager configuration to display branding supplied by
different Fedora or bootc images.

Bazzite supplies a Fish function that normally forces its stock Fastfetch
configuration. The Home Manager Fish feature overrides that function while still
resolving the wrapped executable through `PATH`.

Build it independently with:

```bash
nix build .#fastfetch
./result/bin/fastfetch
```

### Yazi

`features/yazi.nix` builds Yazi with its TOML and Lua configuration embedded.

The configuration:

- displays hidden files;
- retains Yazi's normal three-column layout;
- adds a custom `ls_l` line mode;
- displays file permissions;
- displays human-readable file sizes;
- displays modification timestamps.

The wrapper sets `YAZI_CONFIG_HOME` to an immutable directory in the Nix store.

Build it independently with:

```bash
nix build .#yazi
./result/bin/yazi
```

## Niri

Niri itself is supplied by Fedora rather than Nix.

The repository deliberately keeps the configuration in native KDL instead of
translating it into wrapper-specific Nix attributes. Native KDL remains easier
to compare with Niri documentation and is already well suited to modular
configuration.

Home Manager recursively deploys:

```text
dotfiles/niri
```

to:

```text
~/.config/niri
```

The small top-level `config.kdl` loads the individual modules under `conf/`.

The active configuration covers:

- British keyboard layout;
- touchpad configuration;
- animations;
- window decorations;
- environment variables;
- startup applications;
- keybindings;
- workspace and window behaviour;
- window rules;
- theme settings;
- optional monitor configuration.

An NVIDIA-specific alternative environment file is retained but is not loaded by
the active configuration:

```text
dotfiles/niri/conf/environment.kdl.nvidia
```

The configuration is validated using Fedora's actual Niri binary rather than a
potentially different Nixpkgs build.

Validate it with:

```bash
nix run .#niri-validate
```

or directly:

```bash
/usr/bin/niri validate \
  -c ~/.config/niri/config.kdl
```

Home Manager also validates the configuration before activation.

## Fish and Starship

Fish is the main interactive shell.

The shell feature:

- disables the default Fish greeting;
- starts Fastfetch in interactive shells;
- configures aliases and abbreviations;
- enables Starship;
- enables Zoxide;
- integrates Devenv;
- selects the correct Starship configuration for the current environment.

### Starship selection

The normal host shell uses:

```text
~/.config/starship/starship.toml
```

Toolbox shells use:

```text
~/.config/starship/starship-toolbox.toml
```

Devenv projects may provide their own `STARSHIP_CONFIG`, which is preserved.

The selection logic distinguishes:

```text
DEVENV_ROOT   project-specific Devenv prompt
TOOLBOX_PATH  Toolbox prompt
otherwise     normal host prompt
```

Starship remains file-managed rather than wrapped because the prompt
configuration changes dynamically between the host, Toolbox and Devenv
environments.

### Useful Fish commands

```text
hms       home-manager switch --flake ~/.config/home-manager#tom
ykadd     ssh-add ~/.ssh/id_ed25519_sk_github_yk_1

ls        eza --icons --group-directories-first
ll        eza -lah --icons --group-directories-first --git
la        eza -a --icons --group-directories-first
lt        eza --tree --icons --level=2

lgit      lazygit
ldoc      lazydocker
y         yazi
neofetch  wrapped Fastfetch
```

## Kitty

Kitty is currently supplied by the Fedora host.

Home Manager manages its minimal configuration:

```text
~/.config/kitty/kitty.conf
```

Current font configuration:

```text
Font: JetBrainsMono Nerd Font Mono
Size: 9
```

The font package is installed through the `fonts` feature and Fontconfig is
enabled for the Home Manager profile.

## Neovim with NVF

Neovim is built and configured declaratively through NVF in:

```text
features/editor.nix
```

The configuration provides a LazyVim-inspired environment while remaining fully
expressed in Nix.

Highlights include:

- Tokyo Night Moon theme;
- relative line numbers;
- persistent undo;
- system clipboard integration through `wl-copy`;
- Blink completion;
- LuaSnip and Friendly Snippets;
- LSP support;
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
- Trouble diagnostics;
- Toggleterm;
- integrated Lazygit;
- integrated Yazi.

Configured languages include:

- Nix;
- Bash;
- Fish;
- C and C++;
- Lua;
- Markdown;
- JSON;
- TOML.

The NVF environment also includes the Tree-sitter CLI.

`vi`, `vim` and `nvim` all resolve to the NVF-managed editor.

## Toolbx and Podman

`features/toolbox.nix` defines a custom Fedora 44 Toolbx image:

```text
localhost/toolbox-tom:44
```

The image is based on:

```text
registry.fedoraproject.org/fedora-toolbox:44
```

It includes:

```text
bat
btop
eza
fastfetch
fd-find
fish
fzf
git
kitty-terminfo
neovim
ripgrep
zoxide
```

The image creates:

```text
/nix -> /run/host/nix
```

This exposes the host Nix store at the path expected by Home Manager links and
Nix-installed programs inside Toolbx.

The feature provides:

```bash
toolbox-image-build
```

It is also available as a flake package and app:

```bash
nix build .#toolbox-image-build
nix run .#toolbox-image-build
```

The generated Podman build uses:

- `--pull=newer`;
- `--squash`;
- the declaratively generated Containerfile.

The feature also deploys:

```text
~/.config/containers/toolbox.conf
~/.config/toolbox-tom/Containerfile
~/.config/containers/systemd/toolbox-tom.build
```

## SSH agent and YubiKey workflow

Home Manager enables a user SSH agent with a maximum identity lifetime of 30
days.

A generated `SSH_ASKPASS` wrapper:

- imports the active graphical-session environment from user systemd;
- launches a Zenity password dialog;
- uses the title `YubiKey FIDO2`.

The Fish abbreviation:

```text
ykadd
```

adds:

```text
~/.ssh/id_ed25519_sk_github_yk_1
```

to the agent.

The long agent lifetime does not disable YubiKey PIN or touch requirements. The
key must still be added after reboot.

No private keys, PINs or other secret material are stored in this repository.

## Nix tooling

The `nix-tools` feature installs:

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

Alejandra is exposed as the flake formatter.

Format the repository with:

```bash
nix fmt .
```

## CLI tools

The general CLI feature installs tools including:

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

Configured applications such as Btop, Lazygit, Fastfetch and Yazi are supplied
by their own features rather than the generic package list.

## Devenv

Devenv is installed through its own feature.

Fish loads the Devenv hook after its normal interactive-shell configuration,
allowing trusted projects to enter their environment automatically.

Project-specific Starship configuration is preserved when `DEVENV_ROOT` is set.

## Desktop portals

The portal feature deploys a Niri-specific preference file using:

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
```

This ensures GTK provides the file chooser while retaining suitable GNOME portal
implementations for the remaining interfaces.

## Flake inputs

The main inputs are:

```text
nixpkgs             nixos-26.05
home-manager        release-26.05
flake-parts
import-tree
nix-index-database
NVF
nix-wrapper-modules
```

All inputs are pinned by `flake.lock`.

## Installation

This repository assumes Nix with flakes enabled and standalone Home Manager
installed.

Clone it to the expected location:

```bash
git clone https://github.com/tbuildr/tnxhm \
  ~/.config/home-manager

cd ~/.config/home-manager
```

Inspect the flake:

```bash
nix flake show
```

Build without activating:

```bash
home-manager build --flake .#tom
```

Run checks:

```bash
nix flake check
```

Activate:

```bash
home-manager switch --flake .#tom
```

After the initial activation, the Fish abbreviation can be used:

```fish
hms
```

## Useful commands

### Home Manager

```bash
home-manager build --flake .#tom
home-manager switch --flake .#tom
home-manager generations
```

### Flake maintenance

```bash
nix flake check
nix flake update
nix fmt .
```

### Wrapped packages

```bash
nix build .#btop
nix build .#lazygit
nix build .#fastfetch
nix build .#yazi
```

### Flake apps

```bash
nix run .#toolbox-image-build
nix run .#niri-validate
```

### Cleanup

Remove a temporary `result` link created by `nix build`:

```bash
rm -f result
```

Clean unused Home Manager generations with `nh`:

```bash
nh clean user
```

## Host dependencies

This configuration expects the Fedora or `tbzos` host to supply system-level
components such as:

- Niri and its session integration;
- Kitty;
- Noctalia;
- Fuzzel;
- Swaylock;
- Podman;
- Toolbx;
- graphical and hardware drivers;
- the system Fastfetch logo;
- user scripts referenced from `~/.local/bin`.

This repository is not intended to turn Fedora into NixOS. Fedora remains
responsible for the operating system, while Nix and Home Manager manage the user
environment.

## Testing changes

Changes are normally developed on short-lived Git branches.

Before merging:

```bash
nix fmt .
home-manager build --flake .#tom
nix flake check
home-manager switch --flake .#tom
```

A successful change can then be merged into `main`:

```bash
git switch main
git pull --ff-only
git merge --ff-only <branch-name>
git push origin main
git branch -d <branch-name>
```

## Security

The repository may contain public identifiers and public-key references, but it
must not contain:

- private SSH keys;
- YubiKey PINs;
- access tokens;
- API credentials;
- recovery codes;
- passwords;
- encryption secrets.

Secrets and system authentication configuration remain outside this repository.

## Credits

This configuration builds on:

- Nix;
- Home Manager;
- flake-parts;
- import-tree;
- nix-wrapper-modules;
- NVF;
- Niri;
- Fedora Atomic;
- Universal Blue and Bazzite;
- Devenv;
- Toolbx and Podman.

The repository is intended as a record of my own configuration rather than a
general-purpose framework, but individual features may still be useful as
examples.
