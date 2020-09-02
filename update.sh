#!/usr/bin/env bash
readonly BASEURL="http://conf/20.04/"

readonly LIBREOFFICE_VERSION="libreoffice7.0"
readonly LOO_FILENAME="libreoffice-7.0.0.tar.gz"

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
    printf "${RED}Echec : Une erreur a eu lieu, devine laquelle...${NC}\n"
}

function update {

    lg_echo "Installation de libreoffice : "
    sudo apt -y update \
    && sudo apt -y upgrade \
    && sudo apt -y autoremove --purge \
    && ok || error 
}

function install_libreoffice_web {
    local DEST="/tmp"

    lg_echo "Installation de libreoffice : "
    sudo apt purge -y -qq "libreoffice* libobasis*" \
    && wget -O "${DEST}/${LOO_FILENAME}" "${BASEURL}/${LOO_FILENAME}" \
    && tar xzvf "${DEST}/${LOO_FILENAME}" --directory "${DEST}/" \
    && sudo dpkg -i ${DEST}/libreoffice/*.deb \
    && sudo apt install -yf \
    && rm -r "${DEST}/libreoffice" \
    && rm "${DEST}/${LOO_FILENAME}" \
    && ok || error
}

function main {
    if ! dpkg -s "${LIBREOFFICE_VERSION}" &>/dev/null; then
        install_libreoffice_web
    fi
    update
}

main