#!/bin/bash


#############################################
###  Common functions for Helper Scripts  ###
#############################################


function check_dirname()
{
	# Ueberpruefen, ob wir uns im richtigen Verzeichnis befinden
	
	CURRENT_DIRNAME=${PWD##*/}
	CHECK_DIRNAME="TestFallSteuerung"
	
	if [ "$CURRENT_DIRNAME" != "$CHECK_DIRNAME" ]
	then
		echo "Fehler: Nicht im richtigen Verzeichnis zum Ausfuehren des Scripts, bitte ins Verzeichnis $CHECK_DIRNAME wechseln."
		return 1
	fi
	return 0
}

function check_konnektor_service_ip()
{
	# Ueberpruefen, ob der Konnektor ueber die Service-IP erreichbar ist
	
	ping -c 1 $KONNEKTOR_MNG_IP > /dev/null
	if [ $? -ne 0 ]
	then
		echo "Fehler: Der Konnektor ist nicht ueber die Service-IP erreichbar, bitte Umgebungsvariablen und/oder Testablauf kontrollieren."
		return 1
	fi
	return 0
}
