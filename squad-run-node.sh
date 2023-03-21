#!/bin/bash
KEY_DIR="/keys"
NODE_BASE_DIR="/data/MyObservingSquad"
NODE_DIR_LIST=("0" "1" "2")
META_NODE_BASE_DIR="/MyObservingSquad/node-metachain"
PROXY_BASE_DIR="/MyObservingSquad/proxy"

KEY_DIR="/data/keys"
ORIGINAL_KEY_FILE="validatorKey.pem"
KEY_FILE_LIST=("observerKey_0.pem" "observerKey_1.pem" "observerKey_2.pem" "observerKey_metachain.pem")

generate_key() {
    if [ -e $KEY_DIR ]; then
        echo "pem files dir exists, just skip"
    else
        # docker pull multiversx/chain-keygenerator:latest
        mkdir $KEY_DIR
        for key_file in ${KEY_FILE_LIST[*]}; do
            echo "===== generate $key_file ====="
            docker run --rm -v $KEY_DIR:/keys --workdir /keys multiversx/chain-keygenerator:latest
            mv $KEY_DIR/$ORIGINAL_KEY_FILE $KEY_DIR/$key_file
        done
    fi
}

run() {
    local SHARD=$1
    local DISPLAY_NAME=$2
    local OBSERVER_DIR=$3
    local P2P_PORT=$4
    local IP=$5
    if [ -z $(docker ps -q -f "name=squad-$SHARD") ]; then
        echo "===== run node $SHARD ====="
        if [ "$SHARD" == "metachain" ]; then
            screen -dmS squad-${SHARD} docker run --rm --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} --name squad-${SHARD} multiversx/chain-observer:v1.4.8.1 \
            --destination-shard-as-observer=${SHARD} --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}"
        elif [ "$6" == "lite" ]; then
            screen -dmS squad-${SHARD} docker run --rm --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} --name squad-${SHARD} multiversx/chain-observer:v1.4.8.1 \
            --destination-shard-as-observer=${SHARD} --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}" --operation-mode snapshotless-observer
        else
            screen -dmS squad-${SHARD} docker run --rm --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} --name squad-${SHARD} multiversx/chain-observer:v1.4.8.1 \
            --destination-shard-as-observer=${SHARD} --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}"
        fi
    else
        echo "===== node $SHARD already run ====="
    fi
}

run_squad() {
    # init dir
    for idx in ${NODE_DIR_LIST[*]}; do
        mkdir -p $NODE_BASE_DIR/node-$idx
        cd $NODE_BASE_DIR/node-$idx
        if [ ! -e "config" ]; then
            mkdir config db logs
            cp $KEY_DIR/observerKey_$idx.pem ./config
        fi
    done

    mkdir -p $META_NODE_BASE_DIR
    cd $META_NODE_BASE_DIR
    if [ ! -e "config" ]; then
        mkdir config db logs
        cp $KEY_DIR/observerKey_metachain.pem ./config
    fi

    mkdir -p $PROXY_BASE_DIR/config

    # create a docker network
    if [ -z $(docker network ls -q -f "name=multiversx-squad") ]; then
        docker network create --subnet=10.0.0.0/24 multiversx-squad
    fi

    flag=$1
    # Start Observer of Shard 0
    run 0 "MyObservingSquad-0" $NODE_BASE_DIR/node-0 10000 10.0.0.6 $flag

    # Start Observer of Shard 1
    run 1 "MyObservingSquad-1" $NODE_BASE_DIR/node-1 10001 10.0.0.5 $flag

    # Start Observer of Shard 2
    run 2 "MyObservingSquad-2" $NODE_BASE_DIR/node-2 10002 10.0.0.4 $flag

    # Start Observer of Metachain
    run metachain "MyObservingSquad-metachain" $META_NODE_BASE_DIR 10003 10.0.0.3 $flag

    # Start Proxy
    if [ -z $(docker ps -q -f "name=proxy") ]; then
        IP=10.0.0.2
        screen -dmS proxy docker run --rm --network=multiversx-squad --ip=${IP} --name proxy multiversx/chain-squad-proxy:v1.1.34
    else
        echo "===== proxy already run ====="
    fi

}

# ------------------------------
# main
# ------------------------------
# observer_type: lite, full
echo "===== deploy {{observer_type}} ====="
generate_key
run_squad {{observer_type}}
