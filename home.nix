{ config, pkgs, ... }:


let
  # 1. Define the path to your programs directory
  programsDir = ./config/programs;

  # 2. Get the content of the directory
  files = builtins.readDir programsDir;

  # 3. Filter for directories only (ignoring regular files like .DS_Store or READMEs)
  directories = builtins.filter 
    (name: files.${name} == "directory") 
    (builtins.attrNames files);

  # 4. Map the directory names to import paths (e.g., ./config/programs/zsh)
  #    Nix automatically looks for default.nix inside these folders.
  programImports = map (name: programsDir + "/${name}") directories;
in
{
  imports = [

    # sessions
    ./config/sessions/hyprland/default.nix
  ] ++ programImports; 

  home.username = "ilyamiro";
  home.homeDirectory = "/home/ilyamiro";
  home.stateVersion = "25.11"; 
  
  home.packages = with pkgs; [
      adwaita-icon-theme
  ];

  # set cursor 
  home.pointerCursor = 
  let 
    getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
        name = name;
        size = 24;
        package = 
          pkgs.runCommand "moveUp" {} ''
            mkdir -p $out/share/icons
            # The ArcMidnight zip has the cursor files inside a 'dist' folder, 
            # so we append '/dist' to the fetched source path.
            ln -s ${pkgs.fetchzip {
              url = url;
              hash = hash;
            }}/dist $out/share/icons/${name}
          '';
      };
  in
    getFrom 
      "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE=" # See instructions below
      "ArcMidnight-Cursors";

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
  services.easyeffects.enable = true;  

  gtk = {
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme=1;
      };
  
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme=1;
      };
  
    };
    enable = true;
     };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };
  
  programs.home-manager.enable = true;



  fonts.fontconfig.enable = true; 
  
  home.file = {
    ".local/share/fonts/eww-fonts" = {
      source = config/programs/eww/my-eww-config/fonts; 
      recursive = true;
    };
  };

}

