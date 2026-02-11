# Terra

Live globe wallpaper generator for GNOME and KDE Plasma. Renders a 3D globe showing current day/night cycles, centered on your location, with live weather data and HUD information.

![Screenshot 1 zoomed in globe](https://raw.githubusercontent.com/santiagosantos08/terra/refs/heads/main/screenshots/sc1.png)

![Screenshot 2 zoomed out globe](https://raw.githubusercontent.com/santiagosantos08/terra/refs/heads/main/screenshots/sc2.png)


## Dependencies

Terra requires the following tools. Install them according to your distribution's package manager, the names stay the same across all major distros (Fedora, Debian/Ubuntu, Arch):

```
xplanet jq curl
```

## Installation

Clone the repo

```
git clone https://github.com/santiagosantos08/terra && cd terra
```
Make the installer script executable and run it
```
chmod +x install.sh && ./install.sh
```

The installer will move the scripts to ```~/terra```, download the required map textures, and set up a systemd service to keep the wallpaper updated.

## Configuration

You can customize the appearance (zoom, background color, update interval, etc.) by editing ```~/terra/settings.yaml```. After making changes, restart the service:
```
systemctl --user restart terra
```

## Disclaimer

This project relies on systemd user units to handle the background updates and lifecycle of the script. If you are on a distribution that does not use systemd (e.g., Gentoo, Artix, Devuan), you will need to manually configure the script to run on startup using your init system of choice.

If you don't know what an init system is, you are likely running systemd and the installer will work fine.

## Enjoy :) Make goofy software, who cares.

Todos / stuff you can help with:

- Seasonal maps, NASA provides these, but i made this in 20 minutes, i'll leave it for tomorrow, or someone else. It never snows where i live so idc, but you might.

- Proper night map with visible city lights?? not sure how it would look and there are not as many available.

- Support for more DEs/WMs

- Move the SVG's text to the config file

- Auto change the backgorund color depending on time? not sure..

- Add stars / constellations in the background? scope creep incoming.