# Terra

Live globe wallpaper generator for GNOME and KDE Plasma. Renders a 3D globe showing current day/night cycles, centered on your location, with live weather data and HUD information.

## Dependencies

Terra requires the following tools. Install them according to your distribution's package manager:

### Fedora/Nobara/etc
```
sudo dnf install xplanet jq curl
```

### Debian/Ubuntu/Mint/etc
```
sudo apt install xplanet jq curl
```

### Arch/Cachy/etc
```
sudo pacman -S xplanet jq curl
```

## Installation

Clone the repo

```
git clone https://github.com/santiagosantos08/terra
cd terra
```
Make the installer script executable and run it
```
chmod +x install.sh
./install.sh
```

The installer will move the scripts to ```~/terra```, download the required NASA Blue Marble map textures, and set up a systemd service to keep the wallpaper updated.

## Configuration

You can customize the appearance (zoom, background color, update interval, etc.) by editing ```~/terra/settings.yaml```. After making changes, restart the service:
```
systemctl --user restart terra
```

## Disclaimer

This project relies on systemd user units to handle the background updates and lifecycle of the script. If you are on a distribution that does not use systemd (e.g., Gentoo, Artix, Devuan), you will need to manually configure the script to run on startup using your init system of choice.

If you don't know what an init system is, you are likely running systemd and the installer will work fine.

## Enjoy :) Make goofy software, who cares.
