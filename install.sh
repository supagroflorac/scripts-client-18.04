#!/usr/bin/env bash
BASEURL="http://serveur.cdrflorac.fr/18.04/"

INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq install"
REMOVE="sudo apt-get -y purge"
ADDREPO="sudo add-apt-repository -yu"

SOFTWARE="audacity flashplugin-installer freeplane firefox firefox-locale-fr \
          gimp gimp-help-fr geany freecad inkscape kdenlive krita openshot \
          pdfsam pdfshuffler scribus vim vlc \
          winff thunderbird thunderbird-locale-fr"

HEIGHT=20
WIDTH=60
CHOICE_HEIGHT=7
BACKTITLE="SupAgro Florac"
TITLE="Choix de la configuration"
MENU="Quel type de poste est-ce ?"

OPTIONS=(1 "Un poste fixe d'une salle"
         2 "Un portable libre service"
         3 "Le portable d'un collègue"
         4 "Le poste fixe d'un collègue"
         5 "Le portable d'un étudiant"
         6 "Installation de Keepassxc / Mattermost / Nextcloud")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)


RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

################################################################################
## FUNCTIONS
################################################################################

function lg_echo {
    printf "${GREEN}$1\n"
    printf "%0.s#" $(seq 1 ${#1})
    printf "${NC}\n\n"
}

function ok {
    printf "${GREEN}ok${NC}\n\n"
}

function error {
    printf "${RED}Echec : Une erreur a eu lieu, devine laquelle...${NC}\n"
}

function add_line_to_file {
    line="${1}"
    filename="${2}"

    echo "ligne : $line"
    echo "fichier : $filename"

    if $(! grep -q "${line}" "${filename}"); then
        echo "${line}" |sudo tee -a "${filename}"
    fi
}

function install_software {
    lg_echo "Installation des logiciels courants :"
    echo 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' | sudo debconf-set-selections
    sudo sed -i "s/enabled=1/enabled=0/g" /etc/default/apport \
    && $INSTALL $SOFTWARE \
    && ok || error
}

function saf_configuration {
    lg_echo "Installation des logiciels utilisés a SAF :"
    FILENAME="saf-configuration-all.tgz"
    $INSTALL wine-stable ssh pidgin ocsinventory-agent \
    && wget -O /tmp/${FILENAME} "http://serveur/18.04/${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && sudo ocsinventory-agent \
    && ok || error
}

function ldap_configuration {
    lg_echo "Ajoute l'accès a LDAP pour la liste des comptes utilisateurs : "
    $INSTALL libpam-ldapd
    FILENAME="saf-configuration-ldap.tgz"
    wget -O /tmp/${FILENAME} "http://serveur/18.04/${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && add_line_to_file "session required pam_mkhomedir.so umask=0022 skel=/etc/skel" /etc/pam.d/common-session \
    && sudo systemctl daemon-reload \
    && sudo service nslcd restart \
    && sudo dconf update \
    && ok || error
}

function apt_configuration {
    lg_echo "Configuration de APT  :"
    FILENAME="saf-configuration-apt.tgz"
    wget -O /tmp/${FILENAME} "http://serveur/18.04/${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" --owner=root --group=root --overwrite \
    && sudo chmod ug+x "/etc/apt/detect_proxy.sh" \
    && ok || error
}

function saf_configuration {
    lg_echo "Installe les fichiers de configuration spécifiques a SAF : "
    $INSTALL cifs-utils libpam-mount ocsinventory-agent
    $REMOVE gnome-initial-setup
    FILENAME="saf-configuration-all.tgz"
    lg_echo "Déploiement de la configuration commune : "
    wget -O /tmp/${FILENAME} "http://serveur/18.04/${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && ok || error
}

function remove_snap {
    lg_echo "Supprime snap du système : "
    $REMOVE snapd \
    && ok || error
}

function remove_amazon {
    lg_echo "Supprime Amazon du système : "
    $REMOVE ubuntu-web-launchers \
    && ok || error
}


function update {
    lg_echo "Mise a jour du système : "
    sudo apt  update \
    && sudo apt -qqy upgrade \
    && ok || error
}

function install_keepassxc {
    lg_echo "Installation de Keepassxc : "
    $REMOVE "keepassxc*"
    $ADDREPO ppa:phoerious/keepassxc \
    && $INSTALL keepassxc \
    && ok || error
}

function install_nextcloud {
    lg_echo "Installation de Nextcloud : "
    $REMOVE nextcloud-client*
    $ADDREPO ppa:nextcloud-devs/client  \
    && $INSTALL nextcloud-client nextcloud-client-nautilus \
    && ok || error
}

function install_mattermost {
    lg_echo "Installation de Mattermost : "
    DEST="/tmp/mattermost.deb"
    wget -q -O $DEST http://serveur.cdrflorac.fr/mattermost.deb \
    && sudo dpkg -i $DEST $NODISPLAY
    sudo apt-get install -qqyf $NODISPLAY \
    && rm $DEST \
    && ok || error
}

function install_qgis {
    lg_echo "Installation de Qgis : "
    wget -O - https://qgis.org/downloads/qgis-2017.gpg.key | gpg --import \
    && gpg --export --armor CAEB3DC3BDF7FB45 | sudo apt-key add - \
    && echo "deb https://qgis.org/debian bionic main" | sudo tee "/etc/apt/sources.list.d/qgis.list" \
    && sudo apt update \
    && $INSTALL qgis python-qgis qgis-plugin-grass \
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
    lg_echo "Installation de libreoffice : "
    DEST="/tmp"
    FILENAME="libreoffice.tar.gz"
    # Attention : DPKG ne prend pas en compte l'étoile si dans une chaine de
    # caractère délimitée par ""
    $REMOVE "libreoffice*" \
    && wget -q -O "${DEST}/${FILENAME}" "http://serveur/libreoffice.tar.gz" \
    && cd "${DEST}" \
    && tar xvzf "${DEST}/libreoffice.tar.gz" \
    && cd - \
    && sudo dpkg -i ${DEST}/libreoffice/*.deb \
    && sudo apt install -qqyf \
    && rm -r "${DEST}/libreoffice" \
    && rm "${DEST}/${FILENAME}" \
    && ok || error
}

################################################################################
## MAIN
################################################################################

if [ ! -f "/usr/bin/dialog" ]; then
    lg_echo "Installation de dialog : "
    sudo $INSTALL dialog \
    && ok || error
fi



case $CHOICE in
    1) ## Un poste fixe d'une salle
        clear
        apt_configuration
        remove_snap
        remove_amazon
        remove_welcome_screen
        update
        install_software
        saf_configuration
        ldap_configuration
        install_libreoffice_web
        install_keepassxc
        install_mattermost
        install_qgis
        ;;
    2) ## Un portable libre service
        apt_configuration
        remove_snap
        remove_amazon
        remove_welcome_screen
        update
        install_software
        saf_configuration
        install_libreoffice_web
        install_keepassxc
        install_mattermost
        ;;
    3) ## Le portable d'un collègue
        apt_configuration
        remove_snap
        remove_amazon
        remove_welcome_screen
        update
        install_software
        saf_configuration
        install_libreoffice_web
        install_keepassxc
        install_nextcloud
        install_mattermost
        ;;
    4) ## Le poste fixe d'un collègue
        apt_configuration
        remove_snap
        remove_amazon
        remove_welcome_screen
        update
        install_software
        saf_configuration
        ldap_configuration
        install_libreoffice_web
        install_keepassxc
        install_nextcloud
        install_mattermost
        ;;
    5) ## Le portable d'un étudiant
        remove_amazon
        remove_welcome_screen
        update
        saf_configuration
        install_libreoffice_repo
        ;;

    6) ## installation de keepassxc / mattermost / owncloud
        install_keepassxc
        install_nextcloud
        install_mattermost
        ;;

    7) ## installation de QGIS
        install_qgis
        ;;
esac
