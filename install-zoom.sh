#!/usr/bin/env bash

readonly SRC="https://zoom.us/client/latest/zoom_amd64.deb"

function remove_zoom() {
    sudo apt purge zoom
}

function install_zoom() {
    local dest="/tmp/zoom.deb"
    wget -O "${dest}" "${SRC}"
    sudo apt install ${dest}
    rm ${dest}
}

function main() {
    remove_zoom
    install_zoom
}

main