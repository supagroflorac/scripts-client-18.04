#!/usr/bin/env bash

if [ ! -d build ]; then
    mkdir "build"
fi

function build {
    #sudo chown -R root:root conf/${1}/*
    sudo chmod go-w conf/${1}/*
    tar --owner=root --group=root -czf "build/${1}.tgz" -C conf/${1} .
}

build saf-configuration-all
build saf-configuration-ldap
build saf-configuration-apt

if [ -f sendconf.sh ]; then
    bash sendconf.sh
fi
