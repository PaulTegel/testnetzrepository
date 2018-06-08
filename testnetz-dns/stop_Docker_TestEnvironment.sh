#!/bin/bash

# Dateiname des Shell-Scripts
SCRIPT_FILENAME=$0

source ./utils.sh
source ./utils_docker.sh

function main()
{
	# Docker env-Variablen einlesen
	. ~/testnetz/.env
	
	stop_docker_env
}

main
exit 0
