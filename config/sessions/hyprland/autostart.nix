{config, ... }:

{
   wayland.windowManager.hyprland.settings = {
      "exec-once" = [
	 "swww-daemon"
	 "hypridle"
	 #"eww daemon --config ~/.config/eww/bar"
	 "~/.config/eww/bar/launch_bar.sh --force-open"
	 # "swww img ~/Images/Wallpapers/catpuccin.jpg"
	 "wl-paste --type text --watch cliphist store" 
	 "wl-paste --type image --watch cliphist store"
	 # "rm /tmp/eww* -R"
	 "systemctl --user enable --now easyeffects"
	 "${./scripts/volume_listener.sh}"
	 # "bash ${./scripts/bluetooth_mgr.sh} --daemon"
         # "bash ${./scripts/usb.sh}"
	 "gsettings set org.gnome.desktop.interface cursor-theme 'ArcMidnight-Cursors'"
    	 "gsettings set org.gnome.desktop.interface cursor-size 24"
      ];
   };
}
