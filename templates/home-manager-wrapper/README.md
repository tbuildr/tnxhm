# tnxhm Home Manager wrapper

Edit `flake.nix` and replace:

- `YOUR_USERNAME`
- `/var/home/YOUR_USERNAME`

Then run:

```bash
git init
git add flake.nix README.md
nix flake lock

home-manager build --flake .#YOUR_USERNAME
home-manager switch --flake .#YOUR_USERNAME
```
