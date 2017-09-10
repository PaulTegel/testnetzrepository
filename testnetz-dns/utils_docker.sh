#!/bin/bash


#################################################
###  Common functions for Docker environment  ###
#################################################


function reset_docker_env()
{
	
	# Docker-TestUmgebung auf Anfangsstatus zuruecksetzen.
	# sudo wird wegen Rechte in der Ubuntu-Umgebung verwendet (Scripte laufen unter 'tdocker')
	
	# Docker env-Variablen einlesen
	. .env

	
	if [ ! -z "$KONN_LAN_2_INTERFACE" ]
	then
	    echo "";
	    echo "";
	    echo "KONN_LAN_2_INTERFACE= $KONN_LAN_2_INTERFACE"
	echo "Erstellen und Starten der Docker-Container, Netzwerke, etc."
	CMD="docker-compose -f docker-compose-FHI-2.yml up -d"  # im Hintergrund starten...
	echo $CMD
	#echo $LOCALHOST_PASSWORD | sudo -S $CMD
	echo $LOCALHOST_PASSWORD |  $CMD
	echo ""
	
	
	# Bridge für local-net* ermitteln
	# *) Siehe ~/testnetz/docker-compose-FHI-2.yml
	device=$(ip a | grep "inet 10.33.128.1/24 scope global" | egrep -ow "[br-]+[[:alnum:]]*")
	echo "device=$device"
	
	if [ ! -z "$device" ]
	then
        #Entferne ip von device
        echo "Entferne ip von device"
        CMD="sudo ip a d 10.33.128.1/24 dev $device"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""
	
        # Hinzufügen Netzwerk-Schnittstelle $KONN_LAN_2_INTERFACE zur Bridge(device)
        echo "Hinzufügen Netzwerk-Schnittstelle $KONN_LAN_2_INTERFACE zur Bridge(device)"
        CMD="sudo brctl addif $device $KONN_LAN_2_INTERFACE"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""
	
        sleep 5
		
		# work-station.wp3
		echo "Hinzufügen einer Netzwerk-Route auf WP3"
		CMD="ip route add 10.33.128.221 dev $device"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""
		
		# work-station.wp2
		echo "Hinzufügen einer Netzwerk-Route auf WP2"
		CMD="ip route add 10.33.128.210 dev $device"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""

		# sis-dns.bind9
		echo "Hinzufügen einer Netzwerk-Route auf WP2"
		CMD="ip route add 10.33.128.222 dev $device"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""
								
	fi
	else
	    echo "";
	    echo "Erstellen und Starten der Docker-Container, Netzwerke, etc."
	    CMD="docker-compose -f docker-compose-FHI.yml up "  # im Hintergrund starten...
	    echo $CMD
	    #echo $LOCALHOST_PASSWORD | sudo -S $CMD
	    echo $LOCALHOST_PASSWORD |  $CMD
	    echo ""
	fi
	
	echo "Zuruecksetzen der Docker-TestUmgebung beendet."
	
	return 0
}


function stop_docker_env()
{
	if [ ! -z "ddd" ]
	then
		echo "Fahre die Docker-TestUmgebung runter:"
		echo "Docker System-Service neu starten..."
		CMD="systemctl restart docker"
		echo $CMD
		echo $LOCALHOST_PASSWORD | sudo -S $CMD
		echo ""
	fi
	
	echo ""
	echo "Bereinigen"
	CMD="docker system prune -f"
	echo $CMD
	echo $LOCALHOST_PASSWORD |  $CMD
	echo ""
	
	if [ ! -z "$KONN_LAN_2_INTERFACE" ]
	then
	    echo "";

		#  
		echo "Entferne(falls) existierende Netzwerk-Route auf $KONN_LAN_2_INTERFACE"
		route_to_del=$(ip route s $LE_NETWORK dev $KONN_LAN_2_INTERFACE)
	    if [ ! -z "$route_to_del" ]
	    then
			CMD="ip route d $LE_NETWORK dev $KONN_LAN_2_INTERFACE"
			echo $CMD
			echo $LOCALHOST_PASSWORD | sudo -S $CMD
		fi
		echo ""
		
		bridge=$(brctl show | grep $KONN_LAN_2_INTERFACE | egrep -ow "[br-]+[[:alnum:]]*")
		echo "bridge=$bridge"
		
	    if [ ! -z "$bridge" ]
	    then
			# Freimachen Netzwerk-Schnittstelle $KONN_LAN_2_INTERFACE
			echo "Freimachen Netzwerk-Schnittstelle $KONN_LAN_2_INTERFACE"
			CMD="sudo brctl delif $bridge $KONN_LAN_2_INTERFACE"
			echo $CMD
			echo $LOCALHOST_PASSWORD | sudo -S $CMD
			echo ""
		fi
	
	
	    echo "KONN_LAN_2_INTERFACE= $KONN_LAN_2_INTERFACE"
		echo "Stoppen und Entfernen der Docker-Container, Netzwerke, etc."
		CMD="docker-compose -f docker-compose-FHI-2.yml down"
		echo $CMD
		echo $LOCALHOST_PASSWORD |  $CMD
		echo ""
	
	else
	    echo "";
		echo "Stoppen und Entfernen der Docker-Container, Netzwerke, etc."
		CMD="docker-compose -f docker-compose-FHI.yml down"
		echo $CMD
		echo $LOCALHOST_PASSWORD |  $CMD
		echo ""
	
	fi
	
	echo "Stoppen der Docker-TestUmgebung beendet."
	
	return 0
}



function build_docker_env()
{
	
	echo ""
	echo "Erstellen der Docker-Container, Netzwerke, etc."
	CMD="docker-compose -f docker-compose-FHI.yml up --build -d"  # im Hintergrund starten...
	echo $CMD
	echo $LOCALHOST_PASSWORD | sudo -S $CMD
	#echo $LOCALHOST_PASSWORD |  $CMD
	echo ""
	
	
	echo ""
	echo "Stoppen der Docker-Container, Netzwerke, etc."
	CMD="docker-compose -f docker-compose-FHI.yml down"
	echo $CMD
	echo $LOCALHOST_PASSWORD | sudo -S $CMD
	
	echo ""
	echo "Bereinigen"
	CMD="docker system prune -f"
	echo $CMD
	echo $LOCALHOST_PASSWORD |  $CMD
	echo ""

	
	cd $PWD_BKUP
	
	echo "Build der Docker-TestUmgebung beendet."
	
	return 0
}
