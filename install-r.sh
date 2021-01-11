#!/usr/bin/env bash

readonly R_DEB_SOURCE="deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/"
readonly RSTUDIO_URL_SOURCE="http://conf.cdrflorac.fr/20.04/rstudio-1.3.1093-amd64.deb"

function main() {
    local rstudio_tmp_inst_file="/tmp/rstudio.deb"

    # source : https://cran.r-project.org/bin/linux/ubuntu/
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
    gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | sudo apt-key add -
    echo "${R_DEB_SOURCE}" |sudo tee "/etc/apt/sources.list.d/r.list"
    
    sudo apt update
    sudo apt -y install r-base
    wget -O "${rstudio_tmp_inst_file}" "${RSTUDIO_URL_SOURCE}"
    sudo dpkg -i "${rstudio_tmp_inst_file}"
    sudo apt install -f -y
    rm "${rstudio_tmp_inst_file}"
}

main
