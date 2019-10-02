#!/usr/bin/env bash

ok()
{
    echo -e "\e[32mdone\e[0m"
}

failed()
{
    echo -e "\e[31mfailed\e[0m"
}

sudo apt -y update \
&& sudo apt -y upgrade \
&& sudo apt -y autoremove --purge \
&& echo "Mise à jour : $(ok)" \
|| echo "Mise à jour : $(failed)"

echo -n "Mise à jour des préférence Mozilla/Firefox : "
echo "pref(\"browser.startup.homepage\",\"http://www.cdrflorac.fr\");
pref(\"print.postscript.paper_size\",\"A4\");" | sudo tee /etc/firefox/syspref.js &>/dev/null \
&& ok \
|| failed
