#!/bin/bash
#
# Creates an Ubuntu-machine-/Konektor-individual network interfaces config file /etc/network/interfaces
#
# Ersteller: Gero Matura
# Datum:     2017-05-30
#

# Include variables from Test-Steuerungs-Konfiguration
VARS_CFG_FILENAME="/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/testSteuerungsConfig.sh"
#
if [ -f $VARS_CFG_FILENAME ]
then
    . $VARS_CFG_FILENAME
else
    echo "Error: Config file does not exists: $VARS_CFG_FILENAME"
    exit 1
fi

cat << EOF > /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
#
# NOTE: This is an *atomated* generated config file, please do *not* edit by hand!

# The loopback network interface
auto lo
iface lo inet loopback

# The primary LAN interface
allow-hotplug eth0
iface eth0 inet dhcp

# The Konnektor management/control network interface
auto eth0:0
iface eth0:0 inet static
	address $LOCAL_SERVICE_IP
	netmask 255.255.255.0
	post-up arp -s $KONNEKTOR_MNG_IP $KONNEKTOR_LAN_MAC

# konn-lan
auto enx803f5d091950
iface enx803f5d091950 inet static
	address 192.168.3.100
	netmask 255.255.255.0
EOF

