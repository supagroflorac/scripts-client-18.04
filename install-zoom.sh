#!/usr/bin/env bash

readonly SRC="https://zoom.us/client/latest/zoom_amd64.deb"

readonly SILENT="-qq"
#readonly SILENT=""

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly NC="\033[0m"

function lg_echo {
    printf "\n${GREEN}$1\n"
    printf "%0.s#" $(seq 1 ${#1})
    printf "${NC}\n\n"
}

function ok {
    printf "${GREEN}ok${NC}\n\n"
}

function error {
    local msg="Echec : Une erreur a eu lieu, devine laquelle..."
    printf "%0.s#" $(seq 1 ${#msg})
    printf "${RED}${msg}${NC}\n"
    printf "%0.s#" $(seq 1 ${#msg})
}

function remove_zoom() {
    sudo apt purge zoom \
    && return 0
    return 1
}

function install_zoom() {
    local dest="/tmp/zoom.deb"
    wget -O "${dest}" "${SRC}" \
    && sudo apt install ${dest} \
    && rm ${dest} \
    && return 0
    return 1
}

function main() {
    lg_echo "Remove old version  : "
    remove_zoom \
    && ok || error
    
    lg_echo "Remove all old version  : "
    install_zoom \
    && ok || error
}

main