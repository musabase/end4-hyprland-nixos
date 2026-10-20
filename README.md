# end4-hyprland-nixos
End-4 (illogical-impulse) Hyprland dotfiles on NixOS, installed with flakes and Home Manager. Three .nix files do the NixOS-specific work, so you do not have to translate End-4's Arch packages by hand.

Full guide with screenshots and troubleshooting: [How to Install End-4 (illogical-impulse) on NixOS](https://www.musabase.com/2026/10/install-end-4-hyprland-dotfiles-on-nixos.html)

All credit for the dotfiles goes to [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland). This repo only packages them for NixOS.

## Requirements

- A base NixOS install with flakes enabled: `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
- x86-64, 8 GB RAM or more, about 45 GB free disk space
- Hyprland 0.55 or newer (the flake follows nixos-unstable, which ships it)

## Install

```bash
cd /etc/nixos
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/flake.nix
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/end4.nix
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/end4-home.nix
sudo sed -i "s/users.musabase/users.$(whoami)/" flake.nix
sudo nix-shell -p git --run "nixos-rebuild switch --flake .#nixos"
```

The `sed` line puts your own username into `flake.nix`. The rebuild compiles QuickShell and takes about 20 minutes. When it finishes, run `nixos-rebuild list-generations` (the newest generation shows `True` under Current), reboot, and pick Hyprland in your login manager.

## What each file does

| File | Purpose |
|---|---|
| `flake.nix` | Inputs (nixos-unstable, Home Manager, QuickShell pinned to End-4's commit) and the system wiring |
| `end4.nix` | System side: Hyprland, portals, services, fonts and End-4's packages |
| `end4-home.nix` | User side: QuickShell with its Qt modules, a Python environment, and a clone of End-4's dotfiles at a pinned commit |

## Update

Download the three files again, then rebuild:

```bash
cd /etc/nixos
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/flake.nix
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/end4.nix
sudo curl -fLO https://raw.githubusercontent.com/musabase/end4-hyprland-nixos/main/end4-home.nix
sudo sed -i "s/users.musabase/users.$(whoami)/" flake.nix
sudo nix flake update
sudo nix-shell -p git --run "nixos-rebuild switch --flake .#nixos"
```

![downloading end4.nix files](assets/assets/downloading-end-4-hyprland-dotfiles-configured-for-nixos.webp)

The rebuild does not touch an existing End-4 folder. Move it to the commit pinned in `end4-home.nix`, as your normal user (no sudo):

```bash
REV=$(grep -oP 'dotsRev = "\K[0-9a-f]{40}' /etc/nixos/end4-home.nix)
cd ~/.local/share/end4-dots
git stash
git fetch origin
git checkout --detach $REV
git submodule update --init --recursive
```
![End4 dotfiles on NixOS](assets/assets/assets/end-4-hyprland-dotfiles-on-nixos-4.webp)


Then press Ctrl + Super + R to restart the shell. `git stash` sets aside local changes. Run `git stash pop` afterwards to bring back edits you made on purpose.

## Known limits

Two packages from End-4's Arch list are not in nixpkgs and are not installed: MicroTeX (LaTeX formulas in the AI sidebar) and the Breeze Plus icon theme.

## How it stays current

The pinned End-4 and QuickShell commits are in `end4-home.nix` and `flake.nix`. A GitHub Action checks End-4's repo every week and opens a pull request when something changes. Each update is tested on a fresh NixOS install before it is merged.

## Undo

`sudo nixos-rebuild switch --rollback`, or pick the previous generation from your boot menu.
