#!/bin/bash

#set -x

logFile="containerLogs.txt"
dc="docker-compose "

cd ~/testnetz

# Docker env-Variablen einlesen
. ~/testnetz/.env

if [ -n "$KONN_LAN_2_INTERFACE" ]
then
	specificYML="docker-compose-FHI-2lan-interfaces.yml"
else
	specificYML="docker-compose-FHI.yml"
fi
test ! -f $specificYML && specificYML=""

# Find the respective specific docker-compose.yml:
# It may be labeled by 'FHI' within the naming (e.g. docker-compose-FHI.yml)
#specificYML=`ls -l |grep '.yml' |grep 'FHI' |awk '{print $NF}'`

if [ "$specificYML" != "" ]; then
   $dc -f $specificYML logs -f -t |tee $logFile 
else
   # default: use of 'docker-compose.yml'
   $dc logs -f -t |tee $logFile
fi
