# End-4 illogical-impulse Hyprland dotfiles on NixOS: Home Manager part
# https://github.com/musabase/end4-hyprland-nixos
{ config, lib, pkgs, inputs, osConfig, ... }:
let
   dots = "${config.home.homeDirectory}/.local/share/end4-dots";
   # Pinned together with the quickshell commit in flake.nix (updated by .github/workflows/bump-end4.yml)
   dotsRev = "2f2a376fdb2ad738bf55f693dd0b474b64bb0ab8";

  # QuickShell (End-4's pinned commit) plus the QML modules from End-4's Arch package
  end4-quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules
    (with pkgs.kdePackages; [
      qt5compat qtpositioning qtlocation qtmultimedia qtsensors qtsvg qtimageformats
      qtquicktimeline qtvirtualkeyboard qttools qttranslations qtwayland
      kirigami syntax-highlighting
    ]);

  # Python packages from End-4's sdata/uv/requirements.in
  end4-python = pkgs.python3.withPackages (ps: with ps; [
    build pillow setuptools-scm wheel pywayland psutil kde-material-you-colors
    materialyoucolor libsass material-color-utilities setproctitle click loguru
    pycairo pygobject3 tqdm numpy opencv4 google-auth requests
  ]);
in
{
  # Username and home folder come from your NixOS user; stateVersion from your system
  home.stateVersion = lib.mkDefault osConfig.system.stateVersion;

  home.packages = [ end4-quickshell end4-python ];

  fonts.fontconfig.enable = false;

  # End-4's scripts source this "venv" before running Python
  home.file.".local/state/quickshell/.venv/bin/activate".text = ''
    export VIRTUAL_ENV="${end4-python}"
    export PATH="${end4-python}/bin:$PATH"
    deactivate() { :; }
  '';

  # Clone End-4's dotfiles once and copy the KDE files that apps rewrite
  home.activation.cloneEnd4Dots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config"
    if [ ! -d "${dots}" ]; then
      run ${pkgs.git}/bin/git clone --recurse-submodules \
        https://github.com/end-4/dots-hyprland.git "${dots}"
      run ${pkgs.git}/bin/git -C "${dots}" checkout --detach ${dotsRev}
      run ${pkgs.git}/bin/git -C "${dots}" submodule update --init --recursive
    fi
    for f in kdeglobals dolphinrc konsolerc darklyrc; do
      if [ ! -e "$HOME/.config/$f" ]; then
        run cp "${dots}/dots/.config/$f" "$HOME/.config/$f"
      fi
    done
    if [ ! -e "$HOME/.local/share/icons/illogical-impulse.svg" ]; then
      run mkdir -p "$HOME/.local/share/icons"
      run cp "${dots}/dots/.local/share/icons/illogical-impulse.svg" "$HOME/.local/share/icons/"
    fi
  '';

  # Link End-4's config folders into ~/.config (editable, no rebuild needed)
  xdg.configFile = lib.genAttrs [
    "hypr" "quickshell" "fish" "foot" "fuzzel" "kitty" "matugen" "mpv" "wlogout"
    "Kvantum" "fontconfig" "kde-material-you-colors" "xdg-desktop-portal" "starship.toml"
  ] (name: { source = config.lib.file.mkOutOfStoreSymlink "${dots}/dots/.config/${name}"; });

  xdg.dataFile."konsole".source =
    config.lib.file.mkOutOfStoreSymlink "${dots}/dots/.local/share/konsole";

  # What End-4's installer sets with gsettings
  dconf.settings."org/gnome/desktop/interface" = {
    font-name = "Google Sans Flex Medium 11 @opsz=11,wght=500";
    color-scheme = "prefer-dark";
  };

  programs.home-manager.enable = true;
}
