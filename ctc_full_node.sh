#!/usr/bin/env bash

# Exit script on error
set -e


basedir=$(cd `dirname $0`; pwd)
workspace=${basedir}
source ${workspace}/.env

stateScheme="hash"
syncmode="snap"
gcmode="full"
index=0
extraflags=""

src=${workspace}/.local/config
if [ ! -d "$src" ] ;then
	echo "you must startup validator firstly..."
	exit 1
fi

if [ ! -z "$2" ] ;then
	index=$2
fi

if [ ! -z "$3" ] ;then
	syncmode=$3
fi

if [ ! -z "$4" ] ;then
	extraflags=$4
fi

node=node
dst=${workspace}/.local/fullnode/${node}
rialtoHash=0x227f20712ff8b29ffa40d8b3717d9d95a69c5c7a3017e5216510f0c6339e1d64 # init.log

mkdir -pv $dst/

function init() {
  cp $src/config.toml $dst/ && cp $src/genesis.json $dst/
  ${workspace}/bin/geth init --state.scheme ${stateScheme} --datadir ${dst}/ ${dst}/genesis.json
}

function start() {
  nohup ${workspace}/bin/geth --config $dst/config.toml --port $(( 31000 + $index ))  \
  --datadir $dst --rpc.allow-unprotected-txs --allow-insecure-unlock \
  --db.engine=pebble \
  --miner.gasprice=7110504285714 \
  --http \
  --http.api "eth,net,web3,txpool,trace" \
  --ws.addr 0.0.0.0 --ws.port $(( 8546 + $index )) --ws.api "eth,net,web3,txpool,trace" \
  --http.addr 0.0.0.0 --http.port $(( 8545 + $index )) --http.corsdomain "*" \
  --metrics --metrics.addr 0.0.0.0 --metrics.port $(( 6100 + $index )) --metrics.expensive \
  --syncmode ${syncmode} --gcmode ${gcmode} --state.scheme ${stateScheme} $extraflags \
  --rialtohash ${rialtoHash} --override.passedforktime 0 --override.lorentz 0 --override.maxwell 0 \
  --override.immutabilitythreshold ${FullImmutabilityThreshold} --override.breatheblockinterval ${BreatheBlockInterval} \
  --override.minforblobrequest ${MinBlocksForBlobRequests} --override.defaultextrareserve ${DefaultExtraReserveForBlobRequests} \
  > $dst/ctc-node.log 2>&1 &
  echo $! > $dst/pid
}

function stop() {
  if [ ! -f "$dst/pid" ];then
    echo "$dst/pid not exist"
  else
    kill `cat $dst/pid`
    rm -f $dst/pid
    sleep 5
  fi
}

function clean() {
  stop
  rm -rf $dst/*
}

CMD=$1
case ${CMD} in
reset)
    echo "===== start ===="
#    clean
    init
    start
    echo "===== end ===="
    ;;
stop)
    echo "===== stop ===="
    stop
    echo "===== end ===="
    ;;
start)
    echo "===== start ===="
    start
    echo "===== end ===="
    ;;
restart)
    echo "===== restart ===="
    stop
    start
    echo "===== end ===="
    ;;
clean)
    echo "===== clean ===="
    clean
    echo "===== end ===="
    ;;
*)
    echo "Usage: ctc_full_node.sh reset|start|stop|restart|clean nodeIndex syncmode"
    echo "like: ctc_full_node.sh start 1 snap, it will startup a snapsync node1"
    ;;
esac
