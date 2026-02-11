#!/bin/bash

# TERRA - Live globe wallpaper generator
# Check for updates at https://github.com/santiagosantos08/terra

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/settings.yaml"

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         val=$3; sub(/\r$/, "", val);
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, val);
      }
   }'
}

# Load  Terra config, double check assets if the installer fucked up, generate xplanet config
eval $(parse_yaml "$CONFIG_FILE" "conf_")

if [[ "$conf_general_cache_dir" == *"/home/USERNAME"* ]]; then
    CACHE_DIR="${HOME}/.cache/terra"
else
    CACHE_DIR="$conf_general_cache_dir"
fi
mkdir -p "$CACHE_DIR"

MAP_FILE="$CACHE_DIR/earth_map.png"
if [ ! -f "$MAP_FILE" ] && [ -f "$CACHE_DIR/earth_map.jpg" ]; then
    MAP_FILE="$CACHE_DIR/earth_map.jpg"
fi

if [ ! -f "$MAP_FILE" ]; then
    echo "[ERROR] Map missing. Please ensure earth_map.png is in $CACHE_DIR"
    exit 1
fi

XPLANET_CONF="$CACHE_DIR/xplanet_config.conf"
cat > "$XPLANET_CONF" <<EOF
[earth]
"Earth"
map=$MAP_FILE
EOF

detect_de() {
    if [ "$conf_general_desktop_environment" != "auto" ]; then
        echo "$conf_general_desktop_environment"
        return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        echo "gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        echo "kde"
    else
        echo "gnome" 
    fi
}

get_location() {
    if [ "$conf_location_mode" == "auto" ]; then
        LOC_JSON=$(curl -s --max-time 5 http://ip-api.com/json/)
        if [ $? -eq 0 ]; then
            LAT=$(echo "$LOC_JSON" | jq .lat)
            LON=$(echo "$LOC_JSON" | jq .lon)
            CITY=$(echo "$LOC_JSON" | jq -r .city)
        else
            LAT=$conf_location_manual_lat
            LON=$conf_location_manual_lon
            CITY="Offline"
        fi
    else
        LAT=$conf_location_manual_lat
        LON=$conf_location_manual_lon
        CITY=$conf_location_manual_city
    fi
}


DE=$(detect_de)

while true; do
    get_location
    
    WEATHER_JSON=$(curl -s --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code")
    
    if [[ $? -eq 0 && -n "$WEATHER_JSON" ]]; then
        TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m')
        UNIT=$(echo "$WEATHER_JSON" | jq -r '.current_units.temperature_2m')
        CODE=$(echo "$WEATHER_JSON" | jq -r '.current.weather_code')

        # Convert WMO Weather Codes to text
        case $CODE in
            0) DESC="Clear" ;;
            1|2|3) DESC="Partly Cloudy" ;;
            45|48) DESC="Foggy" ;;
            51|53|55) DESC="Drizzle" ;;
            61|63|65) DESC="Rain" ;;
            71|73|75) DESC="Snow" ;;
            95|96|99) DESC="Thunderstorm" ;;
            *) DESC="Cloudy" ;;
        esac
        WEATHER="${DESC} ${TEMP}${UNIT}"
    else
        WEATHER="N/A"
    fi

    SCREEN_W=${conf_display_width:-1920}
    SCREEN_H=${conf_display_height:-1080}
    ZOOM=${conf_globe_zoom:-65}
    GLOBE_SIZE=$(( SCREEN_H * ZOOM / 100 ))
    BG_HEX=${conf_globe_bg_color:-"#111111"}
    
    # Convert #RRGGBB to 0xRRGGBB for xplanet
    CLEAN_HEX="${BG_HEX//\#/}"
    XPLANET_BG="0x${CLEAN_HEX}"

    RENDER_PATH="$CACHE_DIR/globe_render.png"
    WALLPAPER_PATH="$CACHE_DIR/wallpaper.svg"

    # Render the globe with it's correpsonding shadow and texture
    xplanet \
        -config "$XPLANET_CONF" \
        -body earth \
        -latitude "$LAT" \
        -longitude "$LON" \
        -geometry "${GLOBE_SIZE}x${GLOBE_SIZE}" \
        -output "$RENDER_PATH" \
        -background "$XPLANET_BG" \
        -num_times 1 2>/dev/null

    if [ ! -f "$RENDER_PATH" ]; then
        sleep 10
        continue
    fi

    # Generate .svg, edit as you please, take in to account that even if it's just an svg, Gnome and Plasma allow for different stuff, and none of them support full css like a browser, this is just a sane default that works for both.
    # Use a toggle to bypass GNOME's cache, otherwise it get's stuck on the first one
    # If the file was 'a', make it 'b', and vice versa
    if [[ "$WALLPAPER_PATH" == *"-a.svg" ]]; then
        SUFFIX="b"
    else
        SUFFIX="a"
    fi
    
    WALLPAPER_PATH="$CACHE_DIR/wallpaper-$SUFFIX.svg"
    FILE_URI="file://$WALLPAPER_PATH"

    # 2. GENERATE SVG (Dynamic Background + Base64)
    B64_DATA=$(base64 -w 0 "$RENDER_PATH")
    
    cat > "$WALLPAPER_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="${SCREEN_W}" height="${SCREEN_H}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <rect width="100%" height="100%" fill="${BG_HEX}" />
    
    <image 
        x="$((SCREEN_W / 2 - GLOBE_SIZE / 2 + conf_globe_offset_x))" 
        y="$((SCREEN_H / 2 - GLOBE_SIZE / 2 + conf_globe_offset_y))" 
        width="${GLOBE_SIZE}" 
        height="${GLOBE_SIZE}" 
        xlink:href="data:image/png;base64,${B64_DATA}" 
    />
    
    <text x="60" y="100" font-family="Monospace" font-size="16" fill="#aaaaaa">
        <tspan x="60" dy="1.4em" font-weight="bold" fill="#ffffff">LOC:</tspan> $CITY
        <tspan x="60" dy="1.4em" font-weight="bold" fill="#ffffff">COORDS:</tspan> $LAT, $LON
        <tspan x="60" dy="1.4em" font-weight="bold" fill="#ffffff">WEATHER:</tspan> $WEATHER
        <tspan x="60" dy="2.4em" font-size="12" fill="#555555">UPDATED: $(date '+%H:%M:%S')</tspan>
    </text>
</svg>
EOF

    # Apply
    # you might wanna change the fill/center/whatever mode if you have multiple screens with different resolutions.
    FILE_URI="file://$WALLPAPER_PATH"

    if [ "$DE" == "gnome" ]; then
        gsettings set org.gnome.desktop.background picture-uri "$FILE_URI"
        gsettings set org.gnome.desktop.background picture-uri-dark "$FILE_URI"
        OLD_SUFFIX=$([[ "$SUFFIX" == "a" ]] && echo "b" || echo "a")
        rm -f "$CACHE_DIR/wallpaper-$OLD_SUFFIX.svg"
        
    elif [ "$DE" == "kde" ]; then
        DBUS_CMD="qdbus"
        if command -v qdbus-qt6 &> /dev/null; then DBUS_CMD="qdbus-qt6"; fi
        $DBUS_CMD org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var allDesktops = desktops();
            for (i=0;i<allDesktops.length;i++) {
                d = allDesktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                d.writeConfig('Image', '$WALLPAPER_PATH');
            }
        " > /dev/null
    fi

    sleep "$conf_general_update_interval"
done