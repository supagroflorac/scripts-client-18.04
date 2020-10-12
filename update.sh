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

    lg_echo "Mise a jour du systeme : "
    sudo apt -y update \
    && sudo apt -y upgrade \
    && sudo apt -y autoremove --purge \
    && ok || error 
}

function install_libreoffice_web {
    local tmpdir="/tmp"

    lg_echo "Installation de libreoffice : "
    sudo apt purge -y -qq "libreoffice* libobasis*" &> /dev/null
    sudo wget -O "${tmpdir}/${LOO_FILENAME}" "${BASEURL}/${LOO_FILENAME}" \
    && sudo tar xzvf "${tmpdir}/${LOO_FILENAME}" --directory "${tmpdir}/" \
    && sudo dpkg -i ${tmpdir}/libreoffice/*.deb \
    && sudo apt install -yf \
    && rm -r "${tmpdir}/libreoffice" \
    && rm "${tmpdir}/${LOO_FILENAME}" \
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

function add_default_conf_libreoffice() {
    
    if [[ $(sudo unopkg list --shared | grep -q 'libreoffice-saf-default-configuration') == 1 ]]; then
        local filename="libreoffice-saf-default-configuration.oxt"
        local url="http://conf/"

        lg_echo "Configure Libre Office (boite de dialogue impression)"
        wget -O "/tmp/${filename}" "${url}${filename}" \
        && sudo unopkg add --shared "/tmp/${filename}" \
        && ok || error 
    fi
}

function main {
    if ! dpkg -s "${LIBREOFFICE_VERSION}" &>/dev/null; then
        install_libreoffice_web
    fi

    change_mount_method

    update
}

main