# Quick Installation Script 🚀

``` tx=
git clone https://github.com/linyh212/linyh-arch.git ~/linyh-arch
cd ~/linyh-arch
chmod +x install.sh
./install.sh 
```

# Key Bindings 🎹

## General

- `Super + Q`: Open the terminal (`$terminal`)  
- `Super + E`: Open the file manager (`$fileManager`)  
- `Super + R`: Open the application menu (`$menu`)  
- `Super + L`: Logout using `wlogout`
- `Super + M`: Lock screen

## Window Management & Workspace Navigation

- `Super + C`: Close the active window  
- `Super + V`: Toggle floating mode for the active window  
- `Super + J`: Toggle split mode in the Dwindle layout  
- `Super + P`: Toggle pseudo mode in the Dwindle layout  
- `Super + [Arrow Keys]`: Move focus between windows  
- `Super + Shift + [0–9]`: Move active window to workspace 1–10  
- `Super + [0–9]`: Switch to workspace 1–10  
- `Super + S`: Toggle special workspace `magic`  
- `Super + Shift + S`: Move window to special workspace `magic`  
- `Super + Scroll Up`: Switch to previous workspace  
- `Super + Scroll Down`: Switch to next workspace  
- `Super + Left Click (mouse:272)`: Move window by dragging  
- `Super + Right Click (mouse:273)`: Resize window by dragging  

## Screen Brightness, Volume and Media Control

- `Brightness Up`: Increase screen brightness by 5%  
- `Brightness Down`: Decrease screen brightness by 5%  
- `Volume Up`: Increase the volume by 5%  
- `Volume Down`: Decrease the volume by 5%  
- `Audio Mute`: Toggle audio mute  
- `Mic Mute`: Toggle microphone mute  
- `Play/Pause`: Toggle media playback (`playerctl`)  
- `Next Track`: Play next media track  
- `Previous Track`: Play previous media track  

## Screenshot & Miscellaneous (Not Yet Bound)

> ⚠️ The following actions are **not yet defined** in your Hyprland `bind` config. You may consider adding them:

- `Print Screen`: Take a full screenshot and copy to clipboard  
- `Super + Print Screen`: Screenshot active window  
- `Super + Alt + Print Screen`: Screenshot selected area  
- `Super + Escape`: Open logout menu  
- `Ctrl + Escape`: Toggle Waybar (kill/start)  

Make sure to have applications installed corresponding to the binds. Feel free to customize these keybindings to better suit your needs. You can customize these and add more in your Hyprland configuration file (`~/.config/hypr/hyprland.conf`).
