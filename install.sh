#!/usr/bin/env bash
readonly BASEURL="http://conf.cdrflorac.fr/20.04/"

readonly INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get -y install"
readonly REMOVE="sudo apt-get -y purge"
readonly ADDREPO="sudo add-apt-repository -yu"

readonly SOFTWARE="audacity freeplane firefox firefox-locale-fr \
          gimp gimp-help-fr inkscape kdenlive krita openshot \
          pdfsam pdfshuffler scribus neovim vlc ssh pidgin \
          winff thunderbird thunderbird-locale-fr \
          xul-ext-ublock-origin xul-ext-lightning"

readonly HEIGHT=20
readonly WIDTH=60
readonly CHOICE_HEIGHT=7
readonly BACKTITLE="SupAgro Florac"
readonly TITLE="Choix de la configuration"
readonly MENU="Quel type de poste est-ce ?"

readonly OPTIONS=(1 "Un pc d'une salle"
         2 "Un pc libre service"
         3 "Le poste d'un collègue"
         4 "Le poste fixe d'un collègue"
         5 "Le portable d'un étudiant"
         6 "Install QGis")

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly NC="\033[0m"

################################################################################
## FUNCTIONS
################################################################################

function lg_echo {
    printf "\n${GREEN}$1\n"
    printf "%0.s#" $(seq 1 ${#1})
    printf "${NC}\n\n"
}

function ok {
    printf "${GREEN}ok${NC}\n\n"
}

function error {
    printf "${RED}*****Echec*****${NC}\n"
}

function add_line_to_file {
    local line="${1}"
    local filename="${2}"

    echo "ligne : $line" 
    echo "fichier : $filename"

    if $(! grep -q "${line}" "${filename}"); then
        echo "${line}" |sudo tee -a "${filename}"
    fi
}

function install_software {
    lg_echo "Installation des logiciels courants :"
    # echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | sudo debconf-set-selections
    sudo sed -i "s/enabled=1/enabled=0/g" /etc/default/apport \
    && $INSTALL $SOFTWARE \
    && ok || error
}

function saf_configuration {

    local FILENAME="saf-configuration-all.tgz"

    lg_echo "Installation des logiciels utilisés a SAF :"
    $INSTALL wine-stable ssh pidgin ocsinventory-agent \
    && wget -O /tmp/${FILENAME} "${BASEURL}${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && sudo ocsinventory-agent \
    && ok || error
}

function ldap_configuration {

    local FILENAME="saf-configuration-ldap.tgz"

    lg_echo "Ajoute l'accès a LDAP pour la liste des comptes utilisateurs : "
    $INSTALL libpam-ldapd
    wget -O /tmp/${FILENAME} "${BASEURL}${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && add_line_to_file "session required pam_mkhomedir.so umask=0022 skel=/etc/skel" /etc/pam.d/common-session \
    && sudo systemctl daemon-reload \
    && sudo service nslcd restart \
    && sudo dconf update \
    && ok || error
}

function apt_configuration {
    
    local FILENAME="saf-configuration-apt.tgz"
    
    lg_echo "Configuration de APT  :"
    wget -O /tmp/${FILENAME} "${BASEURL}${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" --owner=root --group=root --overwrite \
    && sudo chmod ug+x "/etc/apt/detect_proxy.sh" \
    && ok || error
}

function saf_configuration {
    
    local FILENAME="saf-configuration-all.tgz"

    lg_echo "Installe les fichiers de configuration spécifiques a SAF : "
    $INSTALL cifs-utils libpam-mount ocsinventory-agent
    $REMOVE gnome-initial-setup
    lg_echo "Déploiement de la configuration commune : "
    wget -O /tmp/${FILENAME} "${BASEURL}${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && ok || error
}

function remove_snap {
    lg_echo "Supprime snap du système : "
    $REMOVE snapd \
    && ok || error
}

function update {
    lg_echo "Mise a jour du système : "
    sudo apt  update \
    && sudo apt -qqy upgrade \
    && sudo apt -qqy autoremove --purge \
    && ok || error
}

function install_keepassxc {
    lg_echo "Installation de Keepassxc : "
    $ADDREPO ppa:phoerious/keepassxc \
    && $INSTALL keepassxc \
    && ok || error
}

function install_nextcloud {
    lg_echo "Installation de Nextcloud : "
    $ADDREPO ppa:nextcloud-devs/client  \
    && $INSTALL nextcloud-client nextcloud-client-nautilus \
    && ok || error
}

function install_qgis {
    lg_echo "Installation de Qgis : "
    wget -qO - "https://qgis.org/downloads/qgis-2020.gpg.key" | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import \
    && sudo chmod +r "/etc/apt/trusted.gpg.d/qgis-archive.gpg" \
    && echo "deb https://qgis.org/ubuntu `lsb_release -c -s` main" | sudo tee "/etc/apt/sources.list.d/qgis.list" \
    && sudo apt update \
    && $INSTALL qgis qgis-plugin-grass \
    && ok || error
}

function install_libreoffice_repo {
    lg_echo "Installation de libreoffice depuis les dépots : "
    $INSTALL libreoffice libreoffice-help-fr libreoffice-l10n-fr \
    && ok || error
}

function remove_welcome_screen {
    lg_echo "Supprime l'écran d'acceuil a la première connexion : "
    $REMOVE gnome-initial-setup \
    && ok || error
}

function install_libreoffice_web {
    lg_echo "Désinstalle LibreOffice, puis installe la dernière version.\n"
    wget -O - http://conf.cdrflorac.fr/20.04/install-loo.sh | bash
}

function install_zoom() {
    lg_echo "Désinstalle Zoom, puis installe la dernière version.\n"
    wget -O - http://conf.cdrflorac.fr/20.04/install-zoom.sh | bash
}


function fix_dictionary {
    $REMOVE "hunspell-en-*" \
    && $INSTALL hunspell hunspell-fr
}

function remove_apt_proxy {
    sudo rm /etc/apt/apt.conf.d/01proxy
}

function disable_autoupdate {
    sudo rm /etc/xdg/autostart/update-notifier.desktop
    sudo systemctl disable apt-daily-upgrade.timer
    sudo systemctl disable apt-daily.timer
    sudo systemctl disable apt-daily.service
    sudo systemctl disable apt-daily-upgrade.service
    sudo systemctl stop apt-daily.service
    sudo systemctl stop apt-daily-upgrade.service
}

function install_gnome_software {
    lg_echo "Installation de Gnome-software : "
    $INSTALL "gnome-software" \
    && sudo apt -y autoremove --purge \
    && ok || error
}

function add_user_safstage {
    lg_echo "Ajoute l'utilisateur safstage : "
    # $(openssl passwd -crypt "${PASS}") pour obtenir le mot de passe chiffré
    sudo useradd -m -p "xj95rTvZk.8VM" "safstage" -s /bin/bash \
    && ok || error
}

################################################################################
## MAIN
################################################################################

function main {
    if [ ! -f "/usr/bin/dialog" ]; then
        lg_echo "Installation de dialog : " \
        && sudo $INSTALL dialog \
        && ok || error
    fi

    local CHOICE=$(dialog \
        --clear \
        --backtitle "$BACKTITLE" \
        --title "$TITLE" \
        --menu "$MENU" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        "${OPTIONS[@]}" \
        2>&1 >/dev/tty)

    clear

    case $CHOICE in
        1) ## Un poste fixe d'une salle
            apt_configuration
            disable_autoupdate
            remove_snap
            remove_welcome_screen
            update
            install_software
            saf_configuration
            ldap_configuration
            install_libreoffice_web
            install_keepassxc
            install_qgis
            fix_dictionary
            add_user_safstage
            install_zoom
            ;;
        2) ## Un portable libre service
            apt_configuration
            remove_snap
            remove_welcome_screen
            update
            install_software
            saf_configuration
            install_libreoffice_web
            install_keepassxc
            fix_dictionary
            install_zoom
            ;;
        3) ## Le portable d'un collègue
            apt_configuration
            remove_snap
            remove_welcome_screen
            update
            install_software
            saf_configuration
            install_libreoffice_web
            install_keepassxc
            install_nextcloud
            install_mattermost
            fix_dictionary
            install_gnome_software
            install_zoom
            ;;
        4) ## Le poste fixe d'un collègue
            apt_configuration
            disable_autoupdate
            remove_snap
            remove_welcome_screen
            update
            install_software
            saf_configuration
            ldap_configuration
            install_libreoffice_web
            install_keepassxc
            install_nextcloud
            install_mattermost
            fix_dictionary
            install_gnome_software
            install_zoom
            ;;
        5) ## Le portable d'un étudiant
            apt_configuration
            remove_welcome_screen
            update
            saf_configuration
            install_libreoffice_repo
            fix_dictionary
            remove_apt_proxy
            install_zoom
            ;;

        6) ## installation de QGIS
            install_qgis
            ;;
    esac
}

main