#!/usr/bin/env bash
PROXY=apt-cacher.cdrflorac.fr
PORT=3142
nc -zw1 $PROXY $PORT && echo http://$PROXY:$PORT/ || echo DIRECT
