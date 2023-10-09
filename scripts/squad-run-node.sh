#!/bin/bash
# for centos 7

set -e
SQUAD_BASE_DIR=/data/MyObservingSquad
FLOAT_MOUNT_DIR=/data/float
PROXY_BASE_DIR=$SQUAD_BASE_DIR/proxy
DEPLOYMENT_MODE_FILE=$SQUAD_BASE_DIR/deployment_mode

KEY_DIR=/data/keys

REGION=`curl http://metadata.tencentyun.com/latest/meta-data/placement/region`
LH_ID={{lighthouse_id}}
CBS_ID_0={{cbs_0}}
CBS_ID_1={{cbs_1}}
CBS_ID_2={{cbs_2}}
CBS_ID_FLOAT={{cbs_float}}

#
export TENCENTCLOUD_SECRET_ID={{secret_id}}
export TENCENTCLOUD_SECRET_KEY={{secret_key}}
export TENCENTCLOUD_REGION=$REGION

pull_docker_images() {
    local dhgenkey="https://registry.hub.docker.com/v2/repositories/multiversx/chain-keygenerator/tags"
    local dhobs="https://registry.hub.docker.com/v2/repositories/multiversx/chain-observer/tags"
    local dhpro="https://registry.hub.docker.com/v2/repositories/multiversx/chain-squad-proxy/tags"
    
    yum install -y -q jq
    local latgenkey=`curl -s -S $dhgenkey | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`
    local latobs=`curl -s -S $dhobs | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`
    local latpro=`curl -s -S $dhpro | jq '."results"[]["name"]' | sed -n '1p' | tr -d '"'`

    docker pull -q multiversx/chain-keygenerator:$latgenkey
    docker tag multiversx/chain-keygenerator:$latgenkey multiversx/chain-keygenerator:using
    docker pull -q multiversx/chain-observer:$latobs
    docker tag multiversx/chain-observer:$latobs multiversx/chain-observer:using
    docker pull -q multiversx/chain-squad-proxy:$latpro
    docker tag multiversx/chain-squad-proxy:$latpro multiversx/chain-squad-proxy:using
}

# input:
#   $1: dir to store key file
#   $2: name of key file
generate_key() {
    if [ -f "$1/$2" ]; then
        echo "===== skip generate key ====="
    else
        echo "===== generate key ====="
        docker run --privileged --rm --mount type=bind,source=$1,destination=/keys --workdir /keys multiversx/chain-keygenerator:using \
        && sudo chown $(whoami) $1/validatorKey.pem \
        && mv $1/validatorKey.pem $1/$2
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
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/chain-observer:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}"
        elif [ "$6" == "lite" ]; then
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/chain-observer:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}" \
            --operation-mode=snapshotless-observer
        else
            screen -dmS squad-${SHARD} docker run --privileged --rm \
            --mount type=bind,source=${OBSERVER_DIR}/db,destination=/go/mx-chain-go/cmd/node/db \
            --mount type=bind,source=${OBSERVER_DIR}/logs,destination=/go/mx-chain-go/cmd/node/logs \
            --mount type=bind,source=${OBSERVER_DIR}/config,destination=/config \
            --publish ${P2P_PORT}:37373 --network=multiversx-squad --ip=${IP} \
            --name squad-${SHARD} multiversx/chain-observer:using \
            --destination-shard-as-observer=${SHARD} \
            --validator-key-pem-file=/config/observerKey_${SHARD}.pem --display-name="${DISPLAY_NAME}"
        fi
    else
        echo "===== node $SHARD already run ====="
    fi
}

init_env_lite() {
    yum install -y -q python3 screen
    # install tccli
    python3 -m pip install pip
    pip3 install -q tccli
}

init_dir_lite() {
    NODE_0_DIR=$SQUAD_BASE_DIR/node-0
    NODE_1_DIR=$SQUAD_BASE_DIR/node-1
    NODE_2_DIR=$SQUAD_BASE_DIR/node-2
    META_NODE_DIR=$SQUAD_BASE_DIR/node-metachain

    mkdir -p $SQUAD_BASE_DIR/{proxy,node-0,node-1,node-2,node-metachain}/{config,logs}
    mkdir -p $SQUAD_BASE_DIR/{node-0,node-1,node-2,node-metachain}/db

    generate_key "$NODE_0_DIR/config" "observerKey_0.pem"
    generate_key "$NODE_1_DIR/config" "observerKey_1.pem"
    generate_key "$NODE_2_DIR/config" "observerKey_2.pem"
    generate_key "$META_NODE_DIR/config" "observerKey_metachain.pem"
}

init_env_db-lookup() {
    echo "===== init env db-lookup ====="
    echo "LH_ID=$LH_ID"
    echo "CBS_ID_0=$CBS_ID_0"
    echo "CBS_ID_1=$CBS_ID_1"
    echo "CBS_ID_2=$CBS_ID_2"
    echo "CBS_ID_FLOAT=$CBS_ID_FLOAT"
    # install python p7zip
    # yum install -y https://repo.ius.io/ius-release-el$(rpm -E '%{rhel}').rpm
    yum install -y -q python3 screen

    # install tccli
    python3 -m pip install pip
    pip3 install -q tccli
}

# input:
#   $1: cbs_id
#   $2: dir to mount
attach_and_mount() {
    if [[ -z `df | grep $2` ]]; then
        if [[ -n `ls -la /dev/disk/by-id/ |grep ${1#*-}` ]]; then
            echo "===== skip attach $1 ====="
        else
            echo "===== attach $1 ====="
            tccli lighthouse AttachDisks --cli-unfold-argument --region $REGION --DiskIds $1 --InstanceId $LH_ID
            sleep 15
        fi
        local tmp=`ls -la /dev/disk/by-id/ |grep ${1#*-}`
        local cbs_dev=${tmp##*/}
        echo "===== mount cbs_dev=$cbs_dev to $2 ====="
        if [[ -n `parted -s /dev/$cbs_dev print 2>&1|grep -i error` ]]; then
            echo "do formt"
            mkfs -t ext4 /dev/$cbs_dev
        fi
        mkdir -p $2
        mount /dev/$cbs_dev $2

        if [ "$2" != "$FLOAT_MOUNT_DIR" ]; then
            echo "===== config /etc/fstab ====="
            echo "/dev/disk/by-id/virtio-disk-${1#*-} $2 ext4 defaults 0 0" >> /etc/fstab
        fi
    else
        echo "===== $1 already mount to $2 ====="
    fi
}


init_dir_db-lookup() {
    CBS_0_DIR=$SQUAD_BASE_DIR/cbs-0
    CBS_1_DIR=$SQUAD_BASE_DIR/cbs-1
    CBS_2_DIR=$SQUAD_BASE_DIR/cbs-2
    NODE_0_DIR=$CBS_0_DIR/node-0
    NODE_1_DIR=$CBS_1_DIR/node-1
    NODE_2_DIR=$CBS_2_DIR/node-2
    META_NODE_DIR=$CBS_0_DIR/node-metachain

    # create CBS

    # attach and mount the disks
    # format
    echo "===== attach and format disks ====="
    echo "TENCENTCLOUD_SECRET_ID=$TENCENTCLOUD_SECRET_ID"
    echo "TENCENTCLOUD_SECRET_KEY=$TENCENTCLOUD_SECRET_KEY"
    attach_and_mount $CBS_ID_0 $CBS_0_DIR
    attach_and_mount $CBS_ID_1 $CBS_1_DIR
    attach_and_mount $CBS_ID_2 $CBS_2_DIR
    attach_and_mount $CBS_ID_FLOAT $FLOAT_MOUNT_DIR


    # copy key files
    mkdir -p $NODE_0_DIR/{logs,config}
    generate_key "$NODE_0_DIR/config" "observerKey_0.pem"
    mkdir -p $NODE_1_DIR/{logs,config}
    generate_key "$NODE_1_DIR/config" "observerKey_1.pem"
    mkdir -p $NODE_2_DIR/{logs,config}
    generate_key "$NODE_2_DIR/config" "observerKey_2.pem"
    mkdir -p $META_NODE_DIR/{logs,config}
    generate_key "$META_NODE_DIR/config" "observerKey_metachain.pem"

    echo "===== download data files ====="
    local ex="tgz"
    # download latest block DBs
    if [ ! -f $FLOAT_MOUNT_DIR/node-0.$ex ]; then
        wget -q https://tommyxyz-1301327510.cos.eu-frankfurt.myqcloud.com/MX/node-0.$ex -P $FLOAT_MOUNT_DIR
    fi
    if [ ! -f $FLOAT_MOUNT_DIR/node-1.$ex ]; then
        wget -q https://tommyxyz-1301327510.cos.eu-frankfurt.myqcloud.com/MX/node-1.$ex -P $FLOAT_MOUNT_DIR
    fi
    if [ ! -f $FLOAT_MOUNT_DIR/node-2.$ex ]; then
        wget -q https://tommyxyz-1301327510.cos.eu-frankfurt.myqcloud.com/MX/node-2.$ex -P $FLOAT_MOUNT_DIR
    fi
    if [ ! -f $FLOAT_MOUNT_DIR/node-metachain.$ex ]; then
        wget -q https://tommyxyz-1301327510.cos.eu-frankfurt.myqcloud.com/MX/node-metachain.$ex -P $FLOAT_MOUNT_DIR
    fi

    # extract block databases in parallel processes
    echo "===== extract database files ====="
    if [[ ! -d $NODE_0_DIR/db/db/1/Static || ! -d $NODE_0_DIR/db/1/Static ]]; then
        tar xf $FLOAT_MOUNT_DIR/node-0.$ex -C $NODE_0_DIR &
    fi
    if [[ ! -d $NODE_1_DIR/db/db/1/Static || ! -d $NODE_1_DIR/db/1/Static ]]; then
        tar xf $FLOAT_MOUNT_DIR/node-1.$ex -C $NODE_1_DIR &
    fi
    if [[ ! -d $NODE_2_DIR/db/db/1/Static || ! -d $NODE_2_DIR/db/1/Static ]]; then
        tar xf $FLOAT_MOUNT_DIR/node-2.$ex -C $NODE_2_DIR &
    fi
    if [[ ! -d $META_NODE_DIR/db/db/1/Static || ! -d $META_NODE_DIR/db/1/Static ]]; then
        tar xf $FLOAT_MOUNT_DIR/node-metachain.$ex -C $META_NODE_DIR &
    fi
    wait

}

cleanup() {
    # clean up
    echo "===== clean up ====="
    if [ "{{deployment_mode}}" != "lite" ]; then
        umount $FLOAT_MOUNT_DIR
        tccli lighthouse DetachDisks --cli-unfold-argument --region $REGION --DiskIds $CBS_ID_FLOAT || true
    fi

    unset TENCENTCLOUD_SECRET_ID
    unset TENCENTCLOUD_SECRET_KEY
}

run_cis_hardening() {
    echo "===== Installing epel-release ... ====="
    yum -y -q install epel-release
    echo "===== Installing ansible ... ====="
    yum -y -q install ansible
    yum -y -q install ansible-core
    echo "===== Installing git ... ====="
    yum -y -q install git
    echo "===== Installing nss ... ====="
    yum -y -q install nss
    git clone https://github.com/ritch2022/terraform-tencentcloud-multiversx-lighthouse.git /home/lighthouse/source-repo/
    cd /home/lighthouse/source-repo/
    echo "===== Running ansible playbook for CIS OS hardening  ... ====="
    ansible-playbook /home/lighthouse/source-repo/scripts/cis-hardening/cis.yml > CIS-ansible.log
}

run_squad() {    
    if [ -f $DEPLOYMENT_MODE_FILE ]; then
        local curr_type=`cat $DEPLOYMENT_MODE_FILE`
        if [ "$1" != $curr_type ]; then
            echo "===== fatal error, different deployment mode: input=$1 current=$curr_type"
            exit 1
        else
            echo "===== already deployed, deployment mode: $1====="
            exit 0
        fi
    fi
    
    # init dir
    if [ "$1" == "lite" ]; then
        init_env_lite
        init_dir_lite
    elif [[ "$1" == "db-lookup-ssd" || "$1" == "db-lookup-hdd" ]]; then
        init_env_db-lookup
        init_dir_db-lookup
    else
        echo "unsupported node type: $1"
        exit 1
    fi

    # create a docker network
    if [ -z $(docker network ls -q -f "name=multiversx-squad") ]; then
        docker network create --subnet=10.0.0.0/24 multiversx-squad
    fi

    # Start Observer of Shard 0
    run 0 "MyObservingSquad-0" $NODE_0_DIR 10000 10.0.0.6 $1
    sleep 30

    # Start Observer of Shard 1
    run 1 "MyObservingSquad-1" $NODE_1_DIR 10001 10.0.0.5 $1
    sleep 30

    # Start Observer of Shard 2
    run 2 "MyObservingSquad-2" $NODE_2_DIR 10002 10.0.0.4 $1
    sleep 30

    # Start Observer of Metachain
    run metachain "MyObservingSquad-metachain" $META_NODE_DIR 10003 10.0.0.3 $1
    sleep 30

    # Start Proxy
    if [ -z $(docker ps -q -f "name=proxy") ]; then
        local IP=10.0.0.2
        screen -dmS proxy docker run --privileged --rm --network=multiversx-squad --ip=${IP} -p 8079:8079 --name proxy multiversx/chain-squad-proxy:using
    else
        echo "===== proxy already run ====="
    fi

    # Write observer type
    echo "$1" > $DEPLOYMENT_MODE_FILE
    
    cleanup
}

# ------------------------------
# main
# ------------------------------
# deployment_mode: lite, db-lookup-hdd, db-lookup-ssd
echo "===== deploy {{deployment_mode}} ====="

run_cis_hardening

pull_docker_images

run_squad {{deployment_mode}}
