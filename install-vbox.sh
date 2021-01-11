#!/usr/bin/env bash

readonly VBOX_KEY_URL="https://www.virtualbox.org/download/oracle_vbox_2016.asc"

function main() {
    wget -O - "${VBOX_KEY_URL}" | sudo apt-key add -
    
    echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sudo apt update
    sudo apt remove --purge virtualbox
    sudo apt install -y virtualbox-6.1
}

main
