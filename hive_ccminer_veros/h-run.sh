#!/usr/bin/env bash

cd "`dirname $0`"

. colors

. h-manifest.conf

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1
CUSTOM_LOG_BASEDIR=`dirname "$CUSTOM_LOG_BASENAME"`
[[ ! -d $CUSTOM_LOG_BASEDIR ]] && mkdir -p $CUSTOM_LOG_BASEDIR

#Checking CUDA version
DRV_VERS=`nvidia-smi --help | head -n 1 | awk '{print $NF}' | sed 's/v//' | tr '.' ' ' | awk '{print $1}'`
echo "Driver version is ${BCYAN}${DRV_VERS}${NOCOLOR}"

if [ ${DRV_VERS} -ge 400 ]; then
   cudaver="10"
elif [ ${DRV_VERS} -ge 396 ]; then
   cudaver="9.2"
elseif
   cudaver="9.1"
fi

echo -e "(${BCYAN}CUDA ${cudaver}${NOCOLOR} compatible)"
minerexe="./ccminer-veros.cuda${cudaver}"

if [ ! -x "${minerexe}" ]; then
   echo "Miner ${miner_archive} required to download."
   put Veros miner binary to "`pwd`/$minerexe"
   exit 1
fi

   ./veros_run "${minerexe}" $(< $CUSTOM_CONFIG_FILENAME) | tee "${CUSTOM_CONFIG_FILENAME}"

