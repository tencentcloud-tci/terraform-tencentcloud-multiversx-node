#!/bin/bash

# this script is suitable for centOS based distributions

set -e

SQUAD_BASE_DIR="/data/MyObservingSquad"
FLOAT_MOUNT_DIR=/data/float
PROXY_BASE_DIR=$SQUAD_BASE_DIR/proxy
DEPLOYMENT_MODE_FILE=$SQUAD_BASE_DIR/.deployment_mode
DOCKER_IMAGE_NODE_NAME_FILE=$SQUAD_BASE_DIR/.node_image_name

NODES=("0" "1" "2" "metachain")
declare -A NODE_0 NODE_1 NODE_2 NODE_META KEY_GENERATOR PROXY

init() {
    if [ ! -f $DEPLOYMENT_MODE_FILE ]; then
        echo "ERROR: .deployment_mode file doesn't exist, please deploy first"
        exit 1
    fi
    CURRENT_DEPLOYMENT_MODE=`cat $DEPLOYMENT_MODE_FILE`

    if [ ! -f $DOCKER_IMAGE_NODE_NAME_FILE ]; then
        echo "ERROR: .node_image_name file doesn't exist, please deploy first"
        exit 1
    fi
    DOCKER_IMAGE_NODE_NAME=`cat $DOCKER_IMAGE_NODE_NAME_FILE`

    NODE_0=( [Image]="multiversx/${DOCKER_IMAGE_NODE_NAME}" [Dir]="$SQUAD_BASE_DIR/node-0" [Name]="MyObservingSquad-0" [IP]="10.0.0.6" [Port]="10000" [Shard]="0" )
    NODE_1=( [Image]="multiversx/${DOCKER_IMAGE_NODE_NAME}" [Dir]="$SQUAD_BASE_DIR/node-1" [Name]="MyObservingSquad-1" [IP]="10.0.0.5" [Port]="10001" [Shard]="1" )
    NODE_2=( [Image]="multiversx/${DOCKER_IMAGE_NODE_NAME}" [Dir]="$SQUAD_BASE_DIR/node-2" [Name]="MyObservingSquad-2" [IP]="10.0.0.4" [Port]="10002" [Shard]="2" )
    NODE_META=( [Image]="multiversx/${DOCKER_IMAGE_NODE_NAME}" [Dir]="$SQUAD_BASE_DIR/node-metachain" [Name]="MyObservingSquad-metachain" [IP]="10.0.0.3" [Port]="10003" [Shard]="metachain" )
    KEY_GENERATOR=( [Image]="multiversx/chain-keygenerator" )
    PROXY=( [Image]="multiversx/chain-squad-proxy" [Dir]="$SQUAD_BASE_DIR/proxy" [IP]="10.0.0.2" [Shard]="proxy" )

    if [[ "$CURRENT_DEPLOYMENT_MODE" == "db-lookup-ssd" || "$CURRENT_DEPLOYMENT_MODE" == "db-lookup-hdd" ]]; then
        CBS_0_DIR=$SQUAD_BASE_DIR/cbs-0
        CBS_1_DIR=$SQUAD_BASE_DIR/cbs-1
        CBS_2_DIR=$SQUAD_BASE_DIR/cbs-2

        NODE_0["Dir"]="$CBS_0_DIR/node-0"
        NODE_1["Dir"]="$CBS_1_DIR/node-1"
        NODE_2["Dir"]="$CBS_2_DIR/node-2"
        NODE_META["Dir"]="$CBS_0_DIR/node-metachain"
    fi

    yum install -y jq
}

# input: 
#   $1: image uri, for example: multiversx/chain-observer
get_image_latest_tag() {
    local url="https://registry.hub.docker.com/v2/repositories/$1/tags"
    NEW_TAG=`curl -s -S $url | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`
}

# input:
#   $1: image uri, for example: multiversx/chain-observer
#   $2: image tag, for example: v1.4.14.0
pull_image() {
    echo "===== Pulling image: $1:$2 ====="
    docker pull $1:$2
    docker tag $1:$2 $1:using
}

# input:
#   $1: shard, option: metachain, 0, 1, 2, proxy
stop_node() {
    if [ "$1" == "proxy" ]; then
        if [[ -n $(docker ps -q -f "name=proxy") ]]; then
            docker container stop proxy
        fi
    else
        if [[ -n $(docker ps -q -f "name=squad-$1") ]]; then
            docker container stop squad-$1
        fi
    fi
}

# input:
#   $1: shard, option: metachain, 0, 1, 2, proxy
#   $2: observer_type
start_node() {
    if [ "$1" == "proxy" ]; then
        if [[ -z $(docker ps -q -f "name=proxy") ]]; then
            echo "===== Running proxy service ====="
            screen -dmS proxy docker run --privileged --rm --network=multiversx-squad --ip=${PROXY["IP"]} -p 8079:8079 --name proxy multiversx/chain-squad-proxy:using
        else
            echo "===== INFO: proxy service already running ====="
        fi
        return 0
    fi

    SHARD=$1
    case "$SHARD" in
        "0")
            local DISPLAY_NAME=${NODE_0["Name"]}
            local OBSERVER_DIR=${NODE_0["Dir"]}
            local P2P_PORT=${NODE_0["Port"]}
            local IP=${NODE_0["IP"]}
            ;;
        "1")
            local DISPLAY_NAME=${NODE_1["Name"]}
            local OBSERVER_DIR=${NODE_1["Dir"]}
            local P2P_PORT=${NODE_1["Port"]}
            local IP=${NODE_1["IP"]}
            ;;
        "2")
            local DISPLAY_NAME=${NODE_2["Name"]}
            local OBSERVER_DIR=${NODE_2["Dir"]}
            local P2P_PORT=${NODE_2["Port"]}
            local IP=${NODE_2["IP"]}
            ;;
        "metachain")
            local DISPLAY_NAME=${NODE_META["Name"]}
            local OBSERVER_DIR=${NODE_META["Dir"]}
            local P2P_PORT=${NODE_META["Port"]}
            local IP=${NODE_META["IP"]}
            ;;
    esac

    if [[ -z $(docker ps -q -f "name=squad-$SHARD") ]]; then
        echo "===== Running node $SHARD ====="
        if [ "$SHARD" == "metachain" ]; then
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/${DOCKER_IMAGE_NODE_NAME}:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}" \
            --operation-mode db-lookup-extension
        elif [ "$2" == "lite" ]; then
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/${DOCKER_IMAGE_NODE_NAME}:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}" \
            --operation-mode=snapshotless-observer
        else
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/${DOCKER_IMAGE_NODE_NAME}:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}" \
            --operation-mode db-lookup-extension
        fi
    else
        echo "===== INFO: node $SHARD already running ====="
    fi
}

# input:
#   $1: shard, option: metachain, 0, 1, 2, proxy
restart_node() {
    echo "===== Restarting node: $1 ====="
    stop_node $1
    sleep 2
    start_node $1 $CURRENT_DEPLOYMENT_MODE
}

stop_all() {
    stop_node ${NODE_0["Shard"]}
    stop_node ${NODE_1["Shard"]}
    stop_node ${NODE_2["Shard"]}
    stop_node ${NODE_META["Shard"]}
    stop_node ${PROXY["Shard"]}
}

start_all() {
    start_node ${NODE_0["Shard"]} $CURRENT_DEPLOYMENT_MODE
    sleep 10
    start_node ${NODE_1["Shard"]} $CURRENT_DEPLOYMENT_MODE
    sleep 10
    start_node ${NODE_2["Shard"]} $CURRENT_DEPLOYMENT_MODE
    sleep 10
    start_node ${NODE_META["Shard"]} $CURRENT_DEPLOYMENT_MODE
    sleep 10
    start_node ${PROXY["Shard"]} $CURRENT_DEPLOYMENT_MODE
}

upgrade() {
    # check node image tag
    local image=${NODE_0["Image"]}
    get_image_latest_tag $image
    if [[ -z $(docker images -q $image:$NEW_TAG) ]]; then
        echo "===== Starting node upgrade ====="
        pull_image $image $NEW_TAG
        restart_node ${NODE_0["Shard"]}
        restart_node ${NODE_1["Shard"]}
        restart_node ${NODE_2["Shard"]}
        restart_node ${NODE_META["Shard"]}
    else
        echo "===== Skipping node upgrade, image already latest ====="
    fi

    # check proxy image tag
    image=${PROXY["Image"]}
    get_image_latest_tag $image
    if [[ -z $(docker images -q $image:$NEW_TAG) ]]; then
        echo "===== Starting proxy upgrade ====="
        pull_image $image $NEW_TAG
        restart_node ${PROXY["Shard"]}
    else
        echo "===== Skip proxy upgrade, image already latest ====="
    fi
}


# input:
#   $1: command: upgrade_all, stop_all, start_all, switch
run_command() {
    if [ "$1" == "upgrade_all" ]; then
        upgrade
    elif [ "$1" == "stop_all" ]; then
        stop_all
    elif [ "$1" == "start_all" ]; then
        start_all
    else
        echo "ERROR: unsupported command: $1"
        exit 1
    fi
}

# ------------------------------
# main
#
# command: upgrade_all, stop_all, start_all, destroy
# ------------------------------
init
run_command {{command}}
