#!/bin/bash
#
# Creates an Linux-machine-/Konektor-individual network interfaces config file /etc/network/interfaces
#
# Ersteller: Gero Matura
# Datum:     2017-05-30, 2017-12-15, 2019-02-20
#

HOME=/home/$SUDO_USER

# Include variables from Test-Steuerungs-Konfiguration
TEST_ENV_VARS_CFG_FILENAME="${HOME}/workspace.docker_branch/TestSuite-Konnektor-T-Systems/testSteuerungsConfig.sh"
#
if [ -f $TEST_ENV_VARS_CFG_FILENAME ]
then
    . $TEST_ENV_VARS_CFG_FILENAME
else
    echo "Error: Config file does not exists: $TEST_ENV_VARS_CFG_FILENAME"
    exit 1
fi

# Include variables from Docker environment
DOCKER_ENV_VARS_CFG_FILENAME="${HOME}/testnetz/.env"
#
if [ -f $DOCKER_ENV_VARS_CFG_FILENAME ]
then
    . $DOCKER_ENV_VARS_CFG_FILENAME
else
    echo "Error: Config file does not exists: $DOCKER_ENV_VARS_CFG_FILENAME"
    exit 1
fi

cat << EOF > /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
#
# NOTE: This is an *atomated* generated config file, please do *not* edit by hand!

# The loopback network interface
auto lo
iface lo inet loopback

# The intranet (LAN) network interface
# The "konn-lan" network interface
auto eth0
iface eth0 inet manual
	up /sbin/dhclient \$IFACE
	down /sbin/dhclient -r \$IFACE

# The Konnektor management/control network interface
auto eth0:0
iface eth0:0 inet static
	address $LOCAL_SERVICE_IP
	netmask 24

# The "konn-wan" network interface
auto $KONN_WAN_INTERFACE
iface $KONN_WAN_INTERFACE inet manual
	up ip link set dev \$IFACE up
	down ip link set dev \$IFACE down

# The "local-net" network interface
auto $KONN_LAN_2_INTERFACE
iface $KONN_LAN_2_INTERFACE inet manual
	up ip link set dev \$IFACE up
	down ip link set dev \$IFACE down
EOF

exit 0
