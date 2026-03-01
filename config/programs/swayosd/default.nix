{ pkgs, config, lib, ... }:

{
   home.packages = with pkgs; [
       swayosd
   ]; 

   services.swayosd = {
  	enable = true;
  	topMargin = 0.9;
        stylePath = "/etc/nixos/config/programs/swayosd/style.css";
};


}

