#!/bin/bash

source ./utils.sh
source ./utils_docker.sh

function main()
{
	
	# Docker env-Variablen einlesen
#	. ~/testnetz/.env
	. .env

	stop_docker_env
	reset_docker_env
	echo "NOTE: Script $SCRIPT_FILENAME wurde ausgefuehrt."
}

main
exit 0
