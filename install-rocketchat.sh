#!/usr/bin/env bash

readonly TAG_NAME="Rocket.Chat.Electron"

function install_package_if_needed()
{
    local package_name="${1}"
    dpkg -s ${package_name} &> /dev/null

    if [ $? -eq 1 ]; then
        sudo apt -y -qqq install ${package_name}
    fi
}

function get_github_last_release()
(
    wget -qqq -O - https://api.github.com/repos/${1}/${2}/releases/latest | jq -r ".tag_name"
)

function main()
{
    install_package_if_needed wget
    install_package_if_needed jq

    local release=$(get_github_last_release "RocketChat" "Rocket.Chat.Electron")
    local tmp_deb="/tmp/rocketchat.deb"
    
    wget -O ${tmp_deb} "https://github.com/RocketChat/Rocket.Chat.Electron/releases/download/${release}/rocketchat_${release}_amd64.deb"
    sudo apt install ${tmp_deb}
    rm ${tmp_deb}
}

main