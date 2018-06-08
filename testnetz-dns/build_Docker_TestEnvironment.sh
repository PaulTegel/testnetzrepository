#!/bin/bash
#
# Setzt die Docker-TestUmgebung auf Anfangsstatus zurueck.
#
# Vorbedingung:
# * keine
#
# NOTE: Das Script muss aus dem Verzeichnis TestFallSteuerung heraus aufgerufen werden!
#
# Ersteller: Paul Weiss
# Datum:     2017-09-06
#

# Dateiname des Shell-Scripts
SCRIPT_FILENAME=$0

################################################################################

# read utility functions
source ./utils_docker.sh



function main()
{
	
	# config-Variablen einlesen
#	. ../testSteuerungsConfig.sh
	
	# Docker env-Variablen einlesen
	. ~/testnetz/.env
	
	build_docker_env
}

################################################################################

main
exit 0
