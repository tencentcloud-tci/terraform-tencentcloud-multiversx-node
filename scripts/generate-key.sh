#!/bin/bash
KEY_DIR="/data/keys"
KEY_FILE="validatorKey.pem"

if [ -e $KEY_DIR/$KEY_FILE ]; then
    echo "pem files dir exists, just skip"
else
    docker pull multiversx/chain-keygenerator:latest
    mkdir $KEY_DIR
    docker run --rm -v $KEY_DIR:/keys --workdir /keys multiversx/chain-keygenerator:latest
fi
