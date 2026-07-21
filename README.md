# Tom's Nix Home Manager configuration

## Overview

This repository contains my personal Nix Home Manager configuration for my
Fedora 44 Atomic/tbzos desktop. See my repo:
[tbzos](https://github.com/tbuildr/tbzos)

It manages my user packages, shell environment, editor configuration and
application dotfiles while leaving operating-system components in the immutable
host image.

The configuration currently targets:

```text
System:         x86_64-linux
Home profile:   tom
Home directory: /var/home/tom
State version:  26.05
```

This is a personal configuration rather than a general-purpose Home Manager
framework. It contains paths, commands and hardware-related assumptions that are
specific to my setup.

<div align="center">

**A declarative user environment for Fedora Atomic/tbzos**

Niri · Noctalia integration · NVF · Fish · Starship · Kitty · Yazi · Toolbx

[![Nix](https://img.shields.io/badge/Nix-Flakes-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![Home Manager](https://img.shields.io/badge/Home%20Manager-26.05-7EBAE4?logo=nixos&logoColor=white)](https://github.com/nix-community/home-manager)
[![Niri](https://img.shields.io/badge/Wayland-Niri-8A2BE2)](https://github.com/niri-wm/niri)
[![Neovim](https://img.shields.io/badge/Neovim-NVF-57A143?logo=neovim&logoColor=white)](https://github.com/NotAShelf/nvf)

</div>

---

## What this repository actually manages

Home Manager actively manages:

- the `tom` Home Manager profile;
- packages from `modules/packages.nix`;
- a custom Fedora 44 Toolbx image definition;
- Neovim through NVF;
- Fish, Starship, Zoxide, Direnv and Nix Index;
- an SSH agent and graphical YubiKey askpass helper;
- Fastfetch, Kitty, Niri, Starship and Yazi dotfiles;
- user environment variables and Fish aliases/abbreviations.

The repository **does not install or fully configure the entire desktop**.

The tbzos host image is expected to provide system-level applications and
services such as Niri, Noctalia, Kitty, Fastfetch, Fuzzel, Swaylock, Podman,
Toolbx, Mullvad and the scripts in `~/.local/bin`.

---

## Repository structure

```text
.
├── dotfiles
│   ├── fastfetch
│   │   ├── bazzite.png
│   │   └── config.jsonc
│   ├── kitty
│   │   └── kitty.conf
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
│   ├── starship
│   │   ├── starship.toml
│   │   └── starship-toolbox.toml
│   └── yazi
│       ├── init.lua
│       └── yazi.toml
├── modules
│   ├── nvf.nix
│   ├── packages.nix
│   └── toolbox.nix
├── flake.lock
├── flake.nix
└── README.md
```

Backup files in some dotfile directories are intentionally omitted from the tree
above.

---

## Flake inputs

The flake uses:

- `nixpkgs` from `nixos-26.05`;
- Home Manager from `release-26.05`;
- NVF from `NotAShelf/nvf`;
- `nix-index-database`.

The active Home Manager module list is:

```nix
nix-index-database.homeModules.default
nvf.homeManagerModules.nvf
./modules/packages.nix
./modules/toolbox.nix
./modules/nvf.nix
```

Fish, Starship, Direnv, the SSH agent and the XDG dotfile links are currently
defined directly in `flake.nix`.

---

# Desktop configuration

## Niri

Home Manager recursively links `dotfiles/niri` to:

```text
~/.config/niri
```

The top-level `config.kdl` is deliberately small and acts as a module loader:

```text
config.kdl
└── conf/
    ├── animations.kdl
    ├── autostart.kdl
    ├── decorations.kdl
    ├── environment.kdl
    ├── inputs.kdl
    ├── keybinds.kdl
    ├── monitors.kdl
    ├── theme.kdl
    └── windowrules.kdl
```

### Active Niri behaviour

The active configuration includes:

- British keyboard layout;
- Num Lock enabled;
- touchpad tap-to-click and natural scrolling;
- screenshots saved under `~/Pictures/Screenshots`;
- dark Adwaita GTK theme;
- client-side decorations disabled where supported;
- eight-pixel gaps;
- one-pixel blue focus ring;
- half-width default columns;
- one-third, one-half and two-thirds column width presets;
- rounded five-pixel window corners;
- Kitty transparency at 90%;
- Firefox picture-in-picture windows opened floating;
- direct scan-out enabled;
- a Noctalia backdrop layer rule.

The monitor file currently contains a commented example output block rather than
an active fixed monitor layout.

An NVIDIA-specific environment file is retained as:

```text
dotfiles/niri/conf/environment.kdl.nvidia
```

It is **not** included by the active `config.kdl`. The active file is
`environment.kdl`.

### Niri startup

Niri currently starts:

```text
noctalia
~/.local/bin/mullvad-vpn-wrapper.sh
~/.local/bin/rclone-mount-dropbox.sh
```

The update checker, Steam startup and SELinux notification examples are present
but commented out.

Noctalia itself is not configured by Home Manager in this repository. Niri only
launches it and sends commands to its CLI.

### Main desktop bindings

| Binding       | Action                                   |
| ------------- | ---------------------------------------- |
| `Mod+Space`   | Toggle the Noctalia launcher             |
| `Mod+S`       | Toggle the Noctalia control centre       |
| `Mod+Shift+S` | Toggle Noctalia settings                 |
| `Mod+Return`  | Open Kitty                               |
| `Mod+D`       | Open Fuzzel                              |
| `Super+Alt+L` | Lock with Swaylock                       |
| `Mod+O`       | Toggle the Niri overview                 |
| `Mod+Q`       | Close the focused window                 |
| `Mod+T`       | Toggle floating mode                     |
| `Mod+Shift+T` | Switch focus between floating and tiling |
| `Mod+F`       | Maximise the focused column              |
| `Mod+Shift+F` | Fullscreen the focused window            |
| `Mod+M`       | Maximise the window to the output edges  |
| `Mod+W`       | Toggle tabbed column display             |
| `Print`       | Interactive screenshot                   |
| `Ctrl+Print`  | Screenshot the output                    |
| `Alt+Print`   | Screenshot the focused window            |

Window and workspace navigation is available through both arrow keys and
Vim-style `H`, `J`, `K`, `L` bindings. Workspaces 1–9 can be focused directly,
and `Mod+Ctrl+1` through `Mod+Ctrl+9` move the current column.

### Global copy and paste

The Niri configuration reserves:

```text
Mod+C    Copy
Mod+V    Paste
```

`Mod+C` copies the current Wayland primary selection into the regular clipboard
using `wl-paste` and `wl-copy`.

`Mod+V` uses `wtype` to send a normal `Ctrl+V` event to the focused application.

Because `Mod+V` is reserved for paste, Niri's floating-window binding was moved
from `Mod+V` to `Mod+T`.

> The copy binding expects `wl-copy` and `wl-paste` to be available on the host.
> `wtype` is installed by `modules/packages.nix`.

Validate the active configuration with:

```bash
niri validate
```

---

# Shell and terminal

## Fish

Fish is enabled through Home Manager and is the main interactive shell.

The configuration:

- clears the default Fish greeting;
- runs Fastfetch when an interactive shell starts;
- adds `~/.local/bin` to the user session path;
- chooses a different Starship configuration inside Toolbx;
- integrates Direnv, Nix Index, Starship and Zoxide.

### Fish abbreviations

| Abbreviation | Expands to                                               |
| ------------ | -------------------------------------------------------- |
| `hms`        | `home-manager switch --flake ~/.config/home-manager#tom` |
| `ykadd`      | `ssh-add ~/.ssh/id_ed25519_sk_github_yk_1`               |

### Fish aliases

| Alias       | Command                                            |
| ----------- | -------------------------------------------------- |
| `ls`        | `eza --icons --group-directories-first`            |
| `ll`        | `eza -lah --icons --group-directories-first --git` |
| `la`        | `eza -a --icons --group-directories-first`         |
| `lt`        | `eza --tree --icons --level=2`                     |
| `bls`       | `/bin/ls`                                          |
| `bvi`       | `/bin/vi`                                          |
| `bat`       | `bat --paging=never`                               |
| `fastfetch` | `/usr/bin/fastfetch`                               |
| `neofetch`  | `/usr/bin/fastfetch`                               |

The explicit `/usr/bin/fastfetch` aliases override Bazzite's stock shell aliases
and ensure the repository's Fastfetch configuration is used.

## Starship

Starship is enabled with Fish integration.

Two prompt files are deployed:

```text
~/.config/starship/starship.toml
~/.config/starship/starship-toolbox.toml
```

Fish checks for `TOOLBOX_PATH`:

```fish
if set -q TOOLBOX_PATH
    set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship-toolbox.toml"
else
    set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
end
```

### Host prompt

The host prompt uses a Gruvbox Dark powerline design and displays:

- operating system and username;
- current directory;
- Git branch and status;
- detected development language versions;
- Docker, Conda or Pixi context;
- current time;
- success, error and Vim-mode prompt indicators.

### Toolbx prompt

The Toolbx prompt uses a deliberately different blue/grey powerline design so
container shells are visually distinct from the host.

## Kitty

Home Manager deploys:

```text
~/.config/kitty/kitty.conf
```

The current Kitty configuration is intentionally minimal:

```text
Font: JetBrainsMono Nerd Font Mono
Size: 9.0
```

The font itself is installed through `modules/packages.nix`, and Fontconfig is
enabled in the Home Manager profile.

Kitty is expected to be installed by the host image; this repository manages its
font configuration only.

---

# Fastfetch

Home Manager deploys:

```text
~/.config/fastfetch/config.jsonc
~/.config/fastfetch/bazzite.png
```

The configuration uses:

- a custom Bazzite PNG logo;
- Kitty's terminal image protocol;
- a Gruvbox-inspired colour palette;
- grouped system, hardware, network, peripheral, media and date/time sections;
- JEDEC sizes such as GB rather than GiB;
- Nerd Font icons;
- memory and disk percentage bars.

Fastfetch itself is expected at:

```text
/usr/bin/fastfetch
```

It is supplied by the tbzos host rather than installed in
`modules/packages.nix`.

---

# Neovim with NVF

## Overview

Neovim is configured declaratively through NVF in:

```text
modules/nvf.nix
```

The configuration is intended to provide a LazyVim-style working environment
while remaining fully expressed in Nix.

`vi`, `vim` and `nvim` all open the NVF-managed editor.

### Core editor settings

- relative line numbers;
- smart-case searching;
- persistent undo;
- two-space indentation;
- spaces instead of tabs;
- splits open below and to the right;
- cursor line and permanent sign column;
- eight lines of scroll context;
- 200 ms update time;
- 300 ms mapping timeout;
- space as the leader key;
- comma as the local leader.

### Wayland clipboard

NVF uses the system clipboard through `wl-copy` and the `unnamedplus` register.

A small Lua hook copies a completed mouse visual selection into Wayland's
primary selection. This allows Niri's global `Mod+C` binding to work with text
selected using the mouse inside Neovim.

### Theme and UI

The editor uses:

```text
Theme: Tokyo Night
Style: Moon
Transparency: Disabled
```

Enabled UI components include:

- Alpha dashboard with a custom NVF ASCII logo;
- Lualine;
- Bufferline;
- Neo-tree;
- Telescope;
- Which-key;
- Noice;
- Illuminate;
- Indent Blankline;
- Web Devicons;
- Fidget;
- bordered UI windows;
- Snacks notifications.

`nvim-notify` is disabled because Snacks provides notifications.

### Completion and editing

- Blink CMP;
- Friendly Snippets;
- LuaSnip;
- nvim-autopairs;
- Comment.nvim;
- Todo Comments;
- surround;
- Leap;
- Diffview.

### LSP and language support

LSP support, formatting on save, Tree-sitter and additional diagnostics are
enabled.

Configured languages:

- Nix;
- Bash;
- Fish;
- C and C++;
- Lua;
- Markdown;
- JSON;
- TOML.

TypeScript, HTML, CSS, Python, Docker and YAML are left as commented future
options.

The `tree-sitter` CLI is added to NVF's wrapped environment.

### Git and terminal integration

- Git integration;
- Gitsigns;
- Toggleterm;
- LazyGit inside Toggleterm;
- Trouble diagnostics;
- Diffview.

Neogit is deliberately disabled because LazyGit covers the preferred Git
workflow.

## NVF key mappings

### Clipboard

| Mapping        | Mode          | Action                                        |
| -------------- | ------------- | --------------------------------------------- |
| `Ctrl+C`       | Visual/Select | Copy selection to the system clipboard        |
| `Ctrl+Shift+C` | Visual/Select | Copy selection to the system clipboard        |
| `Ctrl+V`       | Normal        | Paste after the cursor                        |
| `Ctrl+V`       | Visual        | Replace the selection with clipboard contents |
| `Ctrl+V`       | Insert        | Paste from the clipboard                      |
| `Ctrl+V`       | Command       | Paste from the clipboard                      |
| `<leader>v`    | Normal        | Enter Visual Block mode                       |

### Navigation and tools

| Mapping      | Action                     |
| ------------ | -------------------------- |
| `<leader>e`  | Toggle Neo-tree            |
| `<leader>ff` | Find files                 |
| `<leader>fg` | Search text                |
| `<leader>fb` | Find buffers               |
| `<leader>fr` | Open recent files          |
| `<leader>gg` | Open LazyGit               |
| `<leader>xx` | Toggle Trouble diagnostics |
| `Shift+H`    | Previous buffer            |
| `Shift+L`    | Next buffer                |
| `<leader>bd` | Delete the current buffer  |
| `Esc`        | Clear search highlighting  |

## Yazi inside Neovim

Yazi is integrated through `yazi.nvim` and opens in a floating window.

| Mapping     | Action                                  |
| ----------- | --------------------------------------- |
| `<leader>y` | Open Yazi focused on the current file   |
| `<leader>Y` | Open Yazi in Neovim's current directory |
| `Ctrl+Up`   | Reopen the previous Yazi session        |

Additional settings:

- floating window scale: `0.9`;
- rounded floating border;
- Yazi does not replace Neo-tree as the handler for `nvim .`;
- Snacks is initialised for Yazi but inline image rendering is disabled.

Run NVF's health checks with:

```vim
:checkhealth
```

---

# Standalone Yazi configuration

Yazi is installed through `modules/packages.nix` and configured through:

```text
~/.config/yazi/init.lua
~/.config/yazi/yazi.toml
```

The manager:

- shows hidden files;
- keeps the normal three-column layout;
- uses a custom `ls_l` line mode.

The custom line mode displays:

```text
permissions    human-readable size    modification date
```

This provides an `ls -l`-style summary without replacing Yazi's normal
three-pane file manager layout.

---

# Toolbx and Podman

## Custom Fedora 44 Toolbx image

`modules/toolbox.nix` declaratively creates:

```text
~/.config/toolbox-tom/Containerfile
```

The image is named:

```text
localhost/toolbox-tom:44
```

It is based on:

```text
registry.fedoraproject.org/fedora-toolbox:44
```

Packages installed inside the image:

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

The image also creates:

```text
/nix -> /run/host/nix
```

This exposes the host Nix store at the path expected by Home Manager symlinks
and Nix-installed programs inside Toolbx.

## Default Toolbx image

Home Manager writes:

```text
~/.config/containers/toolbox.conf
```

with `localhost/toolbox-tom:44` as the default image for newly created Toolbx
containers.

## Building the image

The module adds this command to the Home Manager profile:

```bash
toolbox-image-build
```

It builds with Podman using:

- `--pull=newer`;
- `--squash`;
- the declaratively generated Containerfile.

A Podman Quadlet build definition is also deployed to:

```text
~/.config/containers/systemd/toolbox-tom.build
```

After building the image, a new container can use the configured default:

```bash
toolbox create
```

Existing Toolbx containers are not rebuilt automatically when the image changes.

## Podman Docker socket

The user environment defines:

```text
DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

Docker-compatible clients can therefore use the rootless Podman socket when the
corresponding user socket is running.

---

# SSH agent and YubiKey workflow

Home Manager enables a user SSH agent with a maximum identity lifetime of:

```text
2592000 seconds
30 days
```

A generated `SSH_ASKPASS` wrapper opens a Zenity password dialog titled:

```text
YubiKey FIDO2
```

The wrapper imports the active Wayland/X11 and D-Bus session variables from the
user systemd environment before launching Zenity.

The Fish abbreviation:

```bash
ykadd
```

expands to:

```bash
ssh-add ~/.ssh/id_ed25519_sk_github_yk_1
```

This adds the local security-key SSH stub to the agent.

The long agent lifetime does not remove the YubiKey's PIN or physical-touch
requirements, and the key still needs to be added again after a reboot.

Private keys, PINs and secret material are not stored in this repository.

---

# Direnv, Nix Index and `comma`

## Direnv

The profile enables:

- Direnv;
- `nix-direnv`;
- Fish integration.

Projects containing an approved `.envrc` can automatically enter their Nix
development environment.

## Nix Index

`nix-index-database` supplies a pre-generated package index, and Nix Index is
integrated with Fish.

## `comma`

The `comma` command can run a package temporarily without adding it permanently
to the Home Manager profile:

```bash
, cowsay "hello"
```

After that command exits, `cowsay` is not installed as a normal persistent
profile package.

---

# Installed Home Manager packages

`modules/packages.nix` currently installs:

| Category                     | Packages                                                           |
| ---------------------------- | ------------------------------------------------------------------ |
| Nix development              | `alejandra`, `deadnix`, `nix-output-monitor`, `nix-tree`, `statix` |
| Terminal utilities           | `bat`, `eza`, `fd`, `ripgrep`, `zoxide`                            |
| Monitoring                   | `btop`                                                             |
| Git/container TUI tools      | `lazygit`, `lazydocker`                                            |
| Editor and terminal workflow | `neovim`, `tmux`, `yazi`                                           |
| File synchronisation         | `rclone`                                                           |
| Wayland input                | `wtype`                                                            |
| Font                         | `nerd-fonts.jetbrains-mono`                                        |

Fontconfig is enabled so applications can locate the installed Nerd Font.

Some packages are installed without a dedicated Home Manager program
configuration. For example, `tmux` is installed, but its commented example
configuration in `flake.nix` is not currently active.

---

# Environment variables

The profile sets:

```text
EDITOR=nvim
VISUAL=nvim
DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

The user session path also includes:

```text
$HOME/.local/bin
```

This is where the Niri startup wrappers referenced by the configuration are
expected to live.

---

# Installation and activation

## Clone

The repository is intended to live at:

```text
~/.config/home-manager
```

Clone it with:

```bash
git clone git@github.com:tbuildr/tnxhm.git ~/.config/home-manager
cd ~/.config/home-manager
```

## Review personal values

Before using this on another machine, review at least:

```text
homeConfigurations.tom
home.username
home.homeDirectory
home.stateVersion
the YubiKey SSH key-stub path
the Fedora Toolbx release
Niri startup scripts
Niri monitor and graphics settings
```

## Apply

With Home Manager already available:

```bash
home-manager switch --flake ~/.config/home-manager#tom
```

Or use the Fish abbreviation after the first activation:

```bash
hms
```

---

# Updating

Update all locked flake inputs:

```bash
cd ~/.config/home-manager
nix flake update
```

Check that the flake evaluates:

```bash
nix flake check
```

Apply the new generation:

```bash
hms
```

Review and commit the changes:

```bash
git status
git diff
git add .
git commit
git push
```

---

# Useful commands

| Command                    | Purpose                                   |
| -------------------------- | ----------------------------------------- |
| `hms`                      | Apply the `tom` Home Manager profile      |
| `home-manager generations` | List Home Manager generations             |
| `nix flake check`          | Evaluate flake checks                     |
| `nix flake update`         | Update locked inputs                      |
| `niri validate`            | Validate the Niri configuration           |
| `toolbox-image-build`      | Rebuild `localhost/toolbox-tom:44`        |
| `ykadd`                    | Add the YubiKey SSH key stub to the agent |
| `, <command>`              | Temporarily run a command from Nixpkgs    |
| `nvim +checkhealth`        | Open Neovim and run health checks         |

---

# Host dependencies and assumptions

Several commands referenced by these dotfiles are deliberately expected to come
from the tbzos host rather than this Home Manager profile:

- `niri`;
- `noctalia`;
- `kitty`;
- `/usr/bin/fastfetch`;
- `fuzzel`;
- `swaylock`;
- `wl-copy` and `wl-paste`;
- `wpctl`;
- `playerctl`;
- `podman`;
- `toolbox`;
- `zenity`;
- Mullvad VPN;
- the wrapper scripts under `~/.local/bin`.

This separation is intentional:

```text
tbzos image   system packages, drivers, services and desktop executables
Home Manager     user packages, editor, shell and dotfiles
Toolbx image     mutable Fedora development environment
```

---

# Not currently managed

The repository contains comments or placeholders for future work, but the
following are not currently active Home Manager configurations:

- Git identity and Git settings;
- a declarative Tmux configuration;
- Noctalia's own configuration;
- a fixed Niri monitor layout;
- the NVIDIA-specific Niri environment file;
- the commented NVF language modules for TypeScript, HTML, CSS, Python, Docker
  and YAML.

---

# Personal conventions

- `vi`, `vim` and `nvim` all open NVF.
- Fish is the interactive shell.
- Kitty is the primary terminal.
- Niri is the compositor.
- Noctalia supplies the desktop shell.
- Yazi is the terminal file manager.
- LazyGit is the preferred Git TUI.
- Podman provides the Docker-compatible socket.
- User configuration belongs in Home Manager where practical.
- System configuration belongs in the tbzos image.
- Secrets and private keys do not belong in Git.

---

## Credits

This configuration builds on the work of the Nix, Home Manager, NVF, Niri,
Noctalia, Yazi, Starship, Fastfetch and Fedora Toolbx communities.

## Disclaimer

This repository reflects my own machine and workflow. Review every module before
applying it to another system.
