#!/usr/bin/env bash

if [[ ! -e ~/.pub-cache/credentials.json ]]; then
    mkdir -p ~/.pub-cache
    touch ~/.pub-cache/credentials.json
fi

echo $PUB_CREDENTIALS > ~/.pub-cache/credentials.json