#!/usr/bin/env bash

if [[ ! -e ~/.pub-cache/credentials.json ]]; then
    mkdir -p ~/.pub-cache
    touch ~/.pub-cache/credentials.json
fi

cat <<EOF > ~/.pub-cache/credentials.json
{
  "accessToken":"$PUB_ACCESS_TOKEN",
  "refreshToken":"$PUB_REFRESH_TOKEN",
  "tokenEndpoint":"$PUB_TOKEN_ENDPOINT",
  "scopes":[$PUB_SCOPES],
  "expiration":$PUB_EXPIRATION
}
EOF