#!/usr/bin/env bash
readonly BASEURL="http://conf/18.04/"

readonly INSTALL="sudo apt -y install"
readonly REMOVE="sudo apt-get -y purge"
readonly ADDREPO="sudo add-apt-repository -yu"

readonly LIBREOFFICE_VERSION="libreoffice7.0"
readonly LOO_FILENAME="libreoffice-7.0.0.tar.gz"


function lg_echo {
    printf "\n${GREEN}$1\n"
    printf "%0.s#" $(seq 1 ${#1})
    printf "${NC}\n\n"
}

function ok
{
  echo -e "\e[32mdone\e[0m"
}

function error
{
  echo -e "\e[31merror\e[0m"
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

function update {
  sudo apt -y update
  sudo apt -y upgrade
  sudo apt -y autoremove --purge
}

# Mise a jour de clé du dépot QGIS (2/10/2019) /!\ à placer avant l'update
function update_qgis_key {
  if [[ -f "/usr/bin/qgis" ]]; then
    wget -qO - https://qgis.org/downloads/qgis-2020.gpg.key | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import \
    && echo "Mise à jour de la clé de dépot QGIS : $(ok)" \
    || echo "Mise à jour de la clé de dépot QGIS : $(error)"
  fi
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

# Mise a jour des paramètres de Firefox (2/10/2019)
function update_firefox_conf {
  echo "pref(\"browser.startup.homepage\",\"http://www.cdrflorac.fr\");
  pref(\"print.postscript.paper_size\",\"A4\");" | sudo tee /etc/firefox/syspref.js &>/dev/null \
  && echo "Mise à jour des préférence Mozilla/Firefox : $(ok)" \
  || echo "Mise à jour des préférence Mozilla/Firefox : $(error)"
}

# Changement de serveur LDAP (07/2020)
function update_ldap_configuration {

    local FILENAME="saf-configuration-ldap.tgz"
 
    wget -O /tmp/${FILENAME} "${BASEURL}${FILENAME}" \
    && sudo tar xvzf /tmp/${FILENAME} -C "/" \
    && sudo systemctl daemon-reload \
    && sudo service nslcd restart \
    && sudo dconf update \
    && echo "Ajoute l'accès a LDAP pour la liste des comptes utilisateurs : $(ok)" \
    || echo "Ajoute l'accès a LDAP pour la liste des comptes utilisateurs : $(error)"
}

function main {
  # Uniquement si nslcd est installé (sinon ldap n'est pas utilisé).
  if [[ -f "/etc/nslcd.conf" ]]; then
    update_ldap_configuration
  fi
  if ! dpkg -s "${LIBREOFFICE_VERSION}" &>/dev/null; then
        install_libreoffice_web
    fi
  update_firefox_conf
  update_qgis_key
  update
}

main