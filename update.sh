#!/usr/bin/env bash
readonly BASEURL="http://conf/20.04/"

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly NC="\033[0m"

function lg_echo {
    printf "\n${GREEN}$1\n"
    printf "%0.s#" $(seq 1 ${#1})
    printf "\n${NC}\n\n"
}

function ok {
    printf "${GREEN}ok${NC}\n\n"
}

function error {
    printf "${RED}Echec : Une erreur a eu lieu, devine laquelle...${NC}\n"
}

function update {

    lg_echo "Mise a jour du systeme : "
    sudo apt -y update \
    && sudo apt -y upgrade \
    && sudo apt -y autoremove --purge \
    && ok || error 
}

function change_mount_method() {
    local mountfile="/etc/security/pam_mount.conf.xml"
    local filename="saf-configuration-all.tgz"
    
    if [[ -f "${mountfile}" ]]; then
        lg_echo "Changement méthode montage réseau : "
        sudo apt -y purge libpam-mount \
        && sudo rm "${mountfile}" \
        && wget -O /tmp/${filename} "${BASEURL}${filename}" \
        && sudo tar xvzf /tmp/${filename} -C "/" \
        && rm /tmp/$filename \
        && ok || error
    fi
}

function update_zoom() {
    lg_echo "Désinstalle Zoom, puis installe la dernière version.\n"
    wget -O - http://conf.cdrflorac.fr/20.04/install-zoom.sh | bash
}

function update_loo() {
    lg_echo "Désinstalle LibreOffice, puis installe la dernière version.\n"
    wget -O - http://conf.cdrflorac.fr/20.04/install-loo.sh | bash
}

function main {
    change_mount_method
    update
    update_zoom
    update_loo
}

main