# tnxhm

A reusable, feature-oriented Nix Home Manager module for Fedora Atomic (or
similar) systems running Niri.

`tnxhm` is the **public, generic** half of a Home Manager setup. It manages
apps, CLI tools, shell config, and dotfiles that don't depend on who you are.
Anything personal (username, home directory, Git identity, signing keys) lives
in a separate, small **wrapper flake** that imports this module.

```
private/user wrapper  →  imports  →  public tnxhm
```

`tnxhm` never imports or knows about the wrapper. It exports a single module:
`homeModules.default`. It does not export a `homeConfigurations` entry — the
wrapper builds that.

## ⚠️ Shell prompt (Tide) needs a one-time setup

The Fish shell prompt is [Tide](https://github.com/IlanCosman/tide). Tide is
installed as a plugin but is **not auto-configured** — Nix can't run Tide's
interactive configurator during activation.

This means a fresh `home-manager switch` gives you a **blank prompt**. After
first activation, run:

```
tide configure
```

and answer the prompts. This only needs to be done once per machine.

## What's managed

- **Fish** — shell config, aliases (`ls`/`ll`/`la`/`lt` via eza, `lgit`, `ldoc`,
  `y`, etc.), Fastfetch on launch, Tide prompt (see above), Zoxide.
- **Neovim**, configured declaratively via
  [NVF](https://github.com/NotAShelf/nvf) — LazyVim-style setup (Tokyo Night
  Moon theme, Telescope, Neo-tree, Bufferline, Trouble, Gitsigns, integrated
  Lazygit/Yazi, Nix/Bash/Fish/C/Lua/ Markdown/JSON/TOML language support).
  `vi`/`vim`/`nvim` all resolve to it.
- **Niri** — native KDL config deployed to `~/.config/niri/`, validated against
  the host's `/usr/bin/niri` binary both by `home-manager switch` and via
  `nix run .#niri-validate`. Niri itself comes from the host, not Home Manager.
  An alternate NVIDIA environment file is included.
- **Kitty** — configured through Home Manager (font, size), but the `kitty`
  binary itself comes from the host, not Nix, so a terminal still works even if
  Home Manager needs repair.
- **Fonts** — JetBrains Mono and Meslo LG Nerd Fonts, with Fontconfig.
- **SSH agent** — a user agent with a 30-day cached passphrase lifetime and a
  Zenity-based graphical askpass (YubiKey PIN/touch still required). No keys,
  identities, or signing config — that's wrapper territory.
- **Ollama** — rootless, ROCm-backed podman quadlet
  (`~/.config/containers/systemd/ollama-rootless.container`) for local LLM
  inference with GPU passthrough, no `sudo` required. Needs `--ipc=host` to work
  around a rootless HSA memory bug on gfx1200 — see below for details.
- **Toolbox/Podman** — generates a custom Toolbox `Containerfile` (based on
  `fedora-toolbox:44`) with Fish, Git, Neovim, ripgrep, fd, fzf, eza, bat,
  zoxide, btop, and a `/nix` symlink to the host Nix store. Build with
  `nix run .#toolbox-image-build`.
- **Nix tooling** — `nh`, `nix-index` (with Fish integration + `comma`),
  `nix-tree`, `deadnix`, `statix`; Alejandra as the repo formatter
  (`nix fmt .`).
- **CLI tools** — bat, eza, fd, ripgrep, tmux, wtype, lazydocker, rclone.
- **Devenv** — CLI installed, Fish hook loaded after the interactive shell so
  trusted projects auto-activate their environments.
- **Desktop portals** — GTK for the file chooser, GNOME for the rest, on Niri.
- **Wrapped packages** (config baked into the Nix store, no mutable `~/.config`
  file): `btop`, `lazygit`, `fastfetch`, `yazi`. Each can be built standalone,
  e.g. `nix build .#btop && ./result/bin/btop`.

## Repository layout

```
.
├── configs/fastfetch/config.json
├── dotfiles/niri/
│   ├── config.kdl
│   └── conf/*.kdl
├── features/            # one flake-parts module per feature
├── flake-modules/
│   ├── home-manager.nix # combines features into homeModules.default
│   └── templates.nix    # exports the wrapper template
├── templates/home-manager-wrapper/
├── flake.nix
└── flake.lock
```

Every file under `features/` is discovered automatically (via `import-tree`) and
can define `flake.homeModules`, `perSystem.packages`, and/or `perSystem.apps`.

## Installing (via a wrapper)

Don't clone this repo into `~/.config/home-manager` directly — create a small
wrapper instead:

```
mkdir -p ~/.config/home-manager && cd ~/.config/home-manager
nix flake init -t github:tbuildr/tnxhm#home-manager-wrapper
```

Edit the generated `flake.nix` and set:

```nix
username = "YOUR_USERNAME";
homeDirectory = "/var/home/YOUR_USERNAME"; # /home/YOUR_USERNAME on non-Atomic
```

Then, since flakes only see tracked/staged files:

```
git init -b main
git add flake.nix README.md
nix flake lock
git add flake.lock
```

Validate and activate:

```
nix flake check
home-manager build --flake .#YOUR_USERNAME     # dry run
home-manager switch --flake .#YOUR_USERNAME    # activate
```

Then run `tide configure` (see above).

## Keeping personal config in a separate wrapper repo

Your wrapper is the right place for `home.username`, `home.homeDirectory`, Git
name/email/signing config, `allowed_signers`, personal Fish abbreviations, and
any machine-specific env vars. It imports `tnxhm.homeModules.default` alongside
its own modules — never the reverse.

Update the pinned `tnxhm` revision with:

```
nix flake update tnxhm
nix flake check
home-manager switch --flake .#YOUR_USERNAME
```

## Developing tnxhm locally

Test unpushed changes against your existing wrapper:

```
git clone https://github.com/tbuildr/tnxhm ~/.config/tnxhm
home-manager switch \
  --flake ~/.config/home-manager#YOUR_USERNAME \
  --override-input tnxhm path:$HOME/.config/tnxhm
```

Useful commands from a `tnxhm` checkout:

```
nix flake check          # validate
nix flake show            # inspect outputs
nix fmt .                 # format
nix build .#btop|.#lazygit|.#fastfetch|.#yazi
nix run .#niri-validate
nix run .#toolbox-image-build
```

## Host dependencies

The host OS (Fedora Atomic / a custom bootc image) is expected to supply: Nix +
the Nix daemon, Niri and its session integration, Kitty, Podman, Toolbox, GPU
drivers, and desktop/hardware integration. Install these in the host image, not
through Home Manager.

## Scope

Built for Fedora Atomic + Niri. The exported module can be reused elsewhere, but
review it first — it includes opinionated package choices, keybindings, and
shell behaviour, and assumes host-provided software listed above.

## Ollama (rootless, ROCm)

Runs as a rootless user-level podman quadlet with GPU passthrough — no `sudo`
required for any of the commands below. Managed via this repo's Home Manager
config; see `features/ollama.nix` for the quadlet definition.

### Checking it's running

```sh
systemctl --user status ollama-rootless
podman ps --filter name=ollama-rootless
```

Confirm GPU detection — look for a `library=ROCm` or `library=CUDA` line:

```sh
journalctl --user -u ollama-rootless -n 20 --no-pager
```

### Pulling and running a model

```sh
podman exec -it ollama-rootless ollama pull qwen2.5-coder:14b
podman exec -it ollama-rootless ollama run qwen2.5-coder:14b
```

One-off prompt:

```sh
podman exec -it ollama-rootless ollama run qwen2.5-coder:14b "Write a systemd unit that mounts a bind mount"
```

Shell into the container:

```sh
podman exec -it ollama-rootless bash
```

List/remove models:

```sh
podman exec -it ollama-rootless ollama list
podman exec -it ollama-rootless ollama rm MODEL
```

Confirm GPU is loaded for a running model:

```sh
podman exec -it ollama-rootless ollama ps
```

### API

```sh
curl http://127.0.0.1:11434/api/generate -d '{
  "model": "qwen2.5-coder:14b",
  "prompt": "Explain what a bootc image is in one sentence",
  "stream": false
}'
```

Swap `qwen2.5-coder:14b` for any model in the
[Ollama library](https://ollama.com/library).

### Setup notes / gotchas

- Bind-mount dir must exist beforehand — podman won't create it:
  `mkdir -p ~/.ollama-rootless`
- Mount needs `:Z` for SELinux relabeling on Fedora Atomic, or ollama gets
  permission-denied writing into it.
- **Needs `--ipc=host`.** Without it, ROCm's HSA runtime fails to allocate GPU
  memory under rootless podman's default private IPC namespace, crashing every
  model load with `Memory critical error ... Reason: Memory in use` regardless
  of model size. `ShmSize=` alone doesn't fix this and actually conflicts with
  `--ipc=host` if both are set. This is passed via `PodmanArgs=` since Quadlet
  has no native `Ipc=` key.
- Trade-off: `--ipc=host` widens the container's isolation slightly (it can see
  host IPC objects) compared to fully sandboxed IPC — still meaningfully better
  than the rootful/root-mapped alternative, just not perfect isolation.
- Quadlet unit name is derived from filename, not `ContainerName=` — keep them
  matching.
