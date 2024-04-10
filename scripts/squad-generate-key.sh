#!/bin/bash
KEY_DIR="/data/keys"
ORIGINAL_KEY_FILE="validatorKey.pem"
KEY_FILE_LIST=("observerKey_0.pem" "observerKey_1.pem" "observerKey_2.pem" "observerKey_metachain.pem")

generate() {
    docker run --rm -v $KEY_DIR:/keys --workdir /keys multiversx/chain-keygenerator:latest
    mv $KEY_DIR/$ORIGINAL_KEY_FILE $KEY_DIR/$1
}

if [ -e $KEY_DIR ]; then
    echo "pem files dir exists, just skip"
else
    docker pull multiversx/chain-keygenerator:latest
    mkdir $KEY_DIR
    for key_file in ${KEY_FILE_LIST[*]}; do
        echo "generate $key_file"
        generate $key_file
    done
fi
