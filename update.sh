#!/usr/bin/env bash

ok()
{
    echo -e "\e[32mdone\e[0m"
}

failed()
{
    echo -e "\e[31mfailed\e[0m"
}

# Mise a jour de clé du dépot QGIS (2/10/2019) /!\ a placer avant l'update
if [[ -f "/usr/bin/qgis" ]]; then
  wget -q -O- https://qgis.org/downloads/qgis-2019.gpg.key | gpg --import &>/dev/null \
  && gpg --export --armor 51F523511C7028C3 | sudo apt-key add - &>/dev/null \
  && echo "Mise à jour de la clé de dépot QGIS : $(ok)" \
  || echo "Mise à jour de la clé de dépot QGIS : $(failed)"
fi

echo -n "Mise à jour : "
sudo apt -y update &>/dev/null \
&& sudo apt -y upgrade &>/dev/null \
&& sudo apt -y autoremove --purge &>/dev/null \
&& ok \
|| failed

# Mise a jour des paramètres de Firefox (2/10/2019)
echo -n "Mise à jour des préférence Mozilla/Firefox : "
echo "pref(\"browser.startup.homepage\",\"http://www.cdrflorac.fr\");
pref(\"print.postscript.paper_size\",\"A4\");" | sudo tee /etc/firefox/syspref.js &>/dev/null \
&& ok \
|| failed

# Mise a jour de libreoffice si necessaires (2/10/2019)
LIBREOFFICE_VERSION="libreoffice6.3"
if ! dpkg -s "${LIBREOFFICE_VERSION}" &>/dev/null; then
  echo -n "Installation de ${LIBREOFFICE_VERSION} : "
  sudo apt purge -y libreoffice* &>/dev/null \
  && wget -q  -O "/tmp/libreoffice.tgz" "http://serveur/${LIBREOFFICE_VERSION}.tgz" \
  && tar xzf /tmp/libreoffice.tgz --directory /tmp \
  && sudo dpkg -i /tmp/libreoffice/*.deb  &>/dev/null \
  && rm -r /tmp/libreoffice \
  && rm /tmp/libreoffice.tgz \
  && ok \
  || failed
fi
