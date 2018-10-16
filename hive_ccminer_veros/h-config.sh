#!/usr/bin/env bash
# This code is included in /hive/bin/custom function

[[ -z $CUSTOM_TEMPLATE ]] && echo -e "${YELLOW}CUSTOM_TEMPLATE is empty${NOCOLOR}" && return 1
[[ -z $CUSTOM_URL ]] && echo -e "${YELLOW}CUSTOM_URL is empty${NOCOLOR}" && return 1

algo=${CUSTOM_ALGO}

if [ ! -z ${algo} ]; then
   algo="-a ${algo}"
else
   algo="-a veros"
fi

if [ -z ${CUSTOM_PASS} ]; then
   CUSTOM_PASS=x
fi

conf="${algo} -o ${CUSTOM_URL} -u ${CUSTOM_TEMPLATE} -p ${CUSTOM_PASS} ${CUSTOM_USER_CONFIG}"

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && return 1
echo "$conf" > $CUSTOM_CONFIG_FILENAME

