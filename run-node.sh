#!/bin/bash

KEY_DIR="/data/keys"
KEY_FILE="validatorKey.pem"
CONTAINER_NAME="multiversx_node"

pull_docker_images() {
    yum install -y -q jq
    local dhgenkey="https://registry.hub.docker.com/v2/repositories/multiversx/chain-keygenerator/tags"
    local dhmainnet="https://registry.hub.docker.com/v2/repositories/multiversx/chain-mainnet/tags"
    
    local latgenkey=`curl -s -S $dhgenkey | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`
    local latmainnet=`curl -s -S $dhmainnet | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`

    docker pull -q multiversx/chain-keygenerator:$latgenkey
    docker tag multiversx/chain-keygenerator:$latgenkey multiversx/chain-keygenerator:using
    docker pull -q multiversx/chain-mainnet:$latmainnet
    docker tag multiversx/chain-mainnet:$latmainnet multiversx/chain-mainnet:using
}

generate_key() {
    if [ -e $KEY_DIR/$KEY_FILE ]; then
        echo "pem files dir exists, just skip"
    else
        mkdir $KEY_DIR
        docker run --rm -v $KEY_DIR:/keys --workdir /keys multiversx/chain-keygenerator:using
    fi
}

run_node() {
    if [ -z $(docker ps -q -f "name=$CONTAINER_NAME") ]; then
        echo "start node..."
        docker run --name $CONTAINER_NAME -d --rm -v /data/keys:/data \
        -p 37373:37373 -p 38383:38383 -p 8080:8080 \
        multiversx/chain-mainnet:using --validator-key-pem-file="/data/validatorKey.pem" --operation-mode snapshotless-observer
    else
        echo "node exists, just skip"
    fi
}

# ------------------------------
# main
# ------------------------------
pull_docker_images
generate_key
run_node
