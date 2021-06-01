#!/usr/bin/env bash

# Le fichier libreoffice-?-?-?.tgz doit contenir les fichiers .deb necessaire à 
# l'installation dans un dossier 'libreoffice'
#

readonly LOO_INSTALL_FILE="http://conf.cdrflorac.fr/20.04/libreoffice-7.1.3.tgz"
readonly LOO_SAF_EXTENSION="http://conf.cdrflorac.fr/libreoffice-saf-default-configuration.oxt"
readonly LOO_VERSION="libreoffice7.1"

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
    local msg="Error"
    printf "${RED}${msg}${NC}\n"
}

function remove_all_loo_version() {
    sudo apt purge -y ${SILENT} libreoffice* &> /dev/null \
    && return 0

    return 1
}

function install_loo_web {
    local tmpdir="/tmp"
    local filename=$(basename ${LOO_INSTALL_FILE})

    sudo wget -O "${tmpdir}/${filename}" "${LOO_INSTALL_FILE}" \
    && sudo tar xzf "${tmpdir}/${filename}" --directory "${tmpdir}/" \
    && sudo apt install ${SILENT} -y ${tmpdir}/libreoffice/*.deb \
    && sudo rm -r "${tmpdir}/libreoffice" \
    && sudo rm "${tmpdir}/${filename}" \
    && return 0

    return 1
}

function add_default_conf_loo() {
    local unopkg=/opt/${LOO_VERSION}/program/unopkg
    
    sudo $unopkg list --shared | grep -q 'libreoffice-saf-default-configuration'
    if [[ $? == 1 ]]; then
        local filename=$(basename ${LOO_SAF_EXTENSION})

        lg_echo "Configure Libre Office (boite de dialogue impression)"
        wget -O "/tmp/${filename}" "${LOO_SAF_EXTENSION}" \
        && sudo $unopkg add --shared "/tmp/${filename}" \
        && return 0
        return 1
    fi
    return 0
}

function main() {
    lg_echo "Remove all old version  : "
    remove_all_loo_version \
    && ok || error
    
    lg_echo "Install LibreOffice last version  : "
    install_loo_web \
    && ok || error

    lg_echo "Configure LibreOffice : "
    add_default_conf_loo \
    && ok || error
}

main
