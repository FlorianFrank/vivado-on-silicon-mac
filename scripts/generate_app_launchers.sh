#!/bin/bash

container_name="vivado_container"

generate_info_plist() {
    plist_file=$1
    program=$2
    
    # Create the file if it does not exist
    if [ ! -f "$plist_file" ]; then
        touch "$plist_file"
    fi

    echo "Generate Info.plist"
    
    # Write the plist content
    cat <<EOL > "$plist_file"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<plist version="1.0">
    <dict>
        <key>CFBundleDisplayName</key>
        <string>$program</string>
        <key>CFBundleExecutable</key>
        <string>Launch_$program</string>
        <key>CFBundleGetInfoString</key>
        <string>Launch_$program</string>
        <key>CFBundleVersion</key>
        <string>1.0</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleIconFile</key>
        <string>icon</string>
        <key>CFBundleIconName</key>
        <string>icon</string>
        <key>CFBundleIdentifier</key>
        <string>com.ichi4096.launch_$program</string>
    </dict>
</plist>
EOL
}

generate_run_script() {
    echo "Generating launch script for application $1"
    local launchscript="$1"
    local program="$2"

    # Create the file if it does not exist
    if [ ! -f "$launchscript" ]; then
        touch "$launchscript"
    fi

    # Write the script content
    cat <<EOL > "$launchscript"
#!/bin/zsh

# Open XQuartz and Docker
open -a XQuartz
open -a Docker

# Wait for Docker to start
while ! /usr/local/bin/docker ps &> /dev/null; do
    open -a Docker
    sleep 5
done

# Kill XQuartz if it's still running
pkill XQuartz

# Wait for X11 to be available
while ! [ -d "/tmp/.X11-unix" ]; do
    open -a XQuartz
    sleep 5
done

# Run Docker container
/usr/local/bin/docker run --init --rm --name $container_name --mount type=bind,source="/tmp/.X11-unix",target="/tmp/.X11-unix" --mount type=bind,source="$PWD/..",target="/home/user" --platform linux/amd64 x64-linux sudo -H -u user bash /home/user/start_$program.sh &
osascript -e 'tell app "Terminal" to do script " while ! [[ \$(ps aux | grep $container_name | wc -l | tr -d \"\\n\\t \") == \"1\" ]]; do $PWD/../xvcd/bin/xvcd; sleep 1; done; exit"'
EOL
    chmod +x "$launchscript"
}

create_app_icon() {
    echo "Generating App icon for application $1"
    program=$1
    icon_file_path=""
    if [ "$program" == "Vivado" ]; then
        icon_file_path=$(find ../Xilinx/Vivado/*/doc/images/vivado_logo.png)
    fi
    if [ "$program" == "Vitis" ]; then
        icon_file_path=$(find ../Xilinx/Vitis/*/doc/images/ide_icon.png)
    fi
    if [ "$program" == "Vitis_HLS" ]; then
        icon_file_path=$(find ../Xilinx/Vitis_HLS/*/doc/images/vitis_hls_icon.png)
    fi
    if [ -f "$icon_file_path" ]; then
        mkdir -p icon.iconset
        create_app_icon_sizes "$icon_file_path"
        mv icon.icns "$program.app/Contents/Resources/icon.icns"
        rm -rf icon.iconset
    else
        echo "Icon for $program not found"
    fi
}

create_app_icon_sizes() {
    input_file=$1
    sips -z 16 16     "$input_file" --out icon.iconset/icon_16x16.png
    sips -z 32 32     "$input_file" --out icon.iconset/icon_16x16@2x.png
    sips -z 32 32     "$input_file" --out icon.iconset/icon_32x32.png
    sips -z 64 64     "$input_file" --out icon.iconset/icon_32x32@2x.png
    sips -z 64 64     "$input_file" --out icon.iconset/icon_64x64.png
    sips -z 128 128   "$input_file" --out icon.iconset/icon_64x64@2x.png
    sips -z 128 128   "$input_file" --out icon.iconset/icon_128x128.png
    sips -z 256 256   "$input_file" --out icon.iconset/icon_128x128@2x.png
    sips -z 256 256   "$input_file" --out icon.iconset/icon_256x256.png
    sips -z 512 512   "$input_file" --out icon.iconset/icon_256x256@2x.png
    sips -z 512 512   "$input_file" --out icon.iconset/icon_512x512.png
    sips -z 1024 1024 "$input_file" --out icon.iconset/icon_512x512@2x.png

    iconutil -c icns icon.iconset
}

create_app_launcher() {
    echo "Generating app launcher for application $1"
    program=$1
    echo "Generate launcher for $1"
    mkdir -p "$1.app"
    mkdir -p "$1.app/Contents"
    mkdir -p "$1.app/Contents/Resources"
    touch "$1.app/Contents/Resources/file"
    generate_info_plist "$program.app/Contents/Info.plist" "$program"
    generate_run_script "$program.app/Launch_$program" "$program"
    create_app_icon "$program"
}

create_app_launcher "Vitis"
create_app_launcher "Vivado"
create_app_launcher "Vitis_HLS"
