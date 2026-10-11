# End-4 illogical-impulse Hyprland dotfiles on NixOS: system part
# https://github.com/musabase/end4-hyprland-nixos
{ config, lib, pkgs, ... }:
let
  # End-4's UI, reading and expressive fonts (not packaged in nixpkgs)
  end4-fonts = pkgs.runCommand "end4-fonts" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${pkgs.fetchurl {
      name = "GoogleSansFlex.ttf";
      url = "https://raw.githubusercontent.com/end-4/google-sans-flex/251aa5abd30496368f634e54ce2a508fe5a2fdfa/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf";
      hash = "sha256-JRCot6JL6x/oFj6aSYE8z+lrVFNES5RD1CZlyk+jIMk=";
    }} $out/share/fonts/truetype/GoogleSansFlex.ttf
    cp ${pkgs.fetchurl {
      name = "SpaceGrotesk.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/7085eb89a950e85db5b166b7a58d414544b4140c/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf";
      hash = "sha256-rK1t4fyTQ29cDx9BN3Ue8E8a6jBj5wNlNZcP/PvXn3I=";
    }} $out/share/fonts/truetype/SpaceGrotesk.ttf
    cp ${pkgs.fetchurl {
      name = "ReadexPro.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/7085eb89a950e85db5b166b7a58d414544b4140c/ofl/readexpro/ReadexPro%5BHEXP,wght%5D.ttf";
      hash = "sha256-Jou6fh6POxTXmLP7DkDrqj/DkwjJrAAg4vr23xgcww4=";
    }} $out/share/fonts/truetype/ReadexPro.ttf
  '';
in
{
  # Hyprland session and portals
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk kdePackages.xdg-desktop-portal-kde ];
  };

  # Lock screen, settings store, shell, typing tool, authentication
  programs.hyprlock.enable = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.ydotool.enable = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Services End-4's bar and sidebars talk to
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  hardware.i2c.enable = true;
  services.upower.enable = true;
  services.geoclue2.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # End-4 sets QT_QPA_PLATFORMTHEME=kde
  qt = {
    enable = true;
    platformTheme = "kde";
  };

  # Every user set up with Home Manager gets the groups End-4's installer adds
  users.users = lib.genAttrs (lib.attrNames config.home-manager.users) (_: {
    extraGroups = [ "networkmanager" "video" "input" "i2c" "ydotool" ];
  });

  fonts.packages = with pkgs; [
    end4-fonts
    rubik
    material-symbols
    nerd-fonts.jetbrains-mono
    twemoji-color-font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # End-4's Arch meta-packages (sdata/dist-arch), translated to nixpkgs
  environment.systemPackages = with pkgs; [
    # illogical-impulse-basic
    git wget curlFull rsync ripgrep jq yq-go bc cmake xdg-user-dirs cliphist inetutils libnotify
    # illogical-impulse-audio
    cava lxqt.pavucontrol-qt playerctl libdbusmenu-gtk3
    # illogical-impulse-backlight
    brightnessctl ddcutil
    # illogical-impulse-fonts-themes
    adw-gtk3 kdePackages.breeze kdePackages.breeze-icons darkly bibata-cursors eza foot kitty matugen starship
    # illogical-impulse-hyprland
    hyprsunset hypridle hyprpicker wl-clipboard
    # illogical-impulse-kde
    kdePackages.bluedevil kdePackages.plasma-nm kdePackages.polkit-kde-agent-1
    kdePackages.dolphin kdePackages.systemsettings kdePackages.kdialog kdePackages.kconfig
    # illogical-impulse-python (system libraries)
    gtk4 libadwaita libsoup_3 libportal-gtk4 gobject-introspection
    # illogical-impulse-screencapture
    hyprshot grim slurp swappy tesseract wf-recorder
    # illogical-impulse-toolkit
    wtype ydotool upower
    # illogical-impulse-widgets
    fuzzel glib imagemagick songrec translate-shell wlogout libqalculate
  ];
}
