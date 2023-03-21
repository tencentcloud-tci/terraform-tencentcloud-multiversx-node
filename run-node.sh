#!/bin/bash

KEY_DIR="/data/keys"
KEY_FILE="validatorKey.pem"
CONTAINER_NAME="multiversx_node"

generate_key() {
    if [ -e $KEY_DIR/$KEY_FILE ]; then
        echo "pem files dir exists, just skip"
    else
        mkdir $KEY_DIR
        docker run --rm -v $KEY_DIR:/keys --workdir /keys multiversx/chain-keygenerator:latest
    fi
}

run_node() {
    if [ -z $(docker ps -q -f "name=$CONTAINER_NAME") ]; then
        echo "start node..."
        docker run --name $CONTAINER_NAME -d --rm -v /data/keys:/data -p 37373:37373 -p 38383:38383 -p 8080:8080 multiversx/chain-mainnet:v1.4.14.0 --validator-key-pem-file="/data/validatorKey.pem" --operation-mode snapshotless-observer
    else
        echo "node exists, just skip"
    fi
}

# ------------------------------
# main
# ------------------------------
generate_key
run_node
