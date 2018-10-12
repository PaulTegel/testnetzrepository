# The Konnektor-IP
export KONNEKTOR_IP=192.168.2.110

# The Konnektor-WAN-IP
export KONNEKTOR_WAN_IP=192.168.3.50

# Networksegment for the LE Network
export LE_NETWORK=192.168.2.0/24

# The management/control IP of Remote Management Server behind SIS
export REMOTE_MANAGEMENT_MGT_IP=10.60.5.8

# The SIS Test IP
export SIS_TEST_IP=11.222.0.30

# Networksegment for the LE Network
export TESTER_NODE=192.168.2.100

# The IP of the LAN DHCP Server
export LAN_DHCP_SERVER=192.168.2.254

# Temporary IP for WP1 to use while playing with the DHCP-Server of the test lab
export WP1_TMP_IP=192.168.2.20

# Temporary IP for WP2 to use while playing with the DHCP-Server of the test lab
export WP2_TMP_IP=192.168.2.30

# Temporary IP for WP2 to use while playing with the DHCP-Server of the test lab
export WP3_TMP_IP=192.168.2.40

# The gematik.de IP for LAN-WAN testing
export GEMATIK_IP=1.2.3.122

# heise.de IP for LAN-WAN testing (gematik.de doesn't respond to ping)
export HEISE_IP=1.2.3.122

# The IP address of the INTRANET_TEST_NODE
export INTRANET_TEST_NODE=192.168.2.100

# The path to the Bestandsnetze.xml on the KSR Server
export KSR_BESTANDSNETZE_SERVER_PATH=/opt/KSRSimulation/files/Bestandsnetze.xml

# An IP in NET_TI_DEZENTRAL segment to use for network firewall/ping tests
export NET_TI_DEZENTRAL_IP=172.20.0.10

# The Card Terminal Simulation toolkit to use
export CT_SIM="FHI"

# IP for WP2 in a network segment in ANLW_LEKTR_INTRANET_ROUTES to use for network firewall/ping tests
export WP2_INTRANET_IP=192.168.2.111

# IP for WP3 in a network segment in ANLW_LEKTR_INTRANET_ROUTES to use for network firewall/ping tests
export WP3_INTRANET_IP=192.168.2.112

export sqlite3_Konnektor=$(sshpass -p123456 ssh -p2222 root@10.10.8.15 'ls /opt/secure/current/extern/bin/ | grep sqlite3') &>/dev/null

NET_TI_ZENTRAL_NTP_IP=172.24.0.65
export NTP_INNER_IP=$NET_TI_ZENTRAL_NTP_IP

# The IP Adress of sis-webserver 
export SIS_WEBSERVER_IP=10.60.5.74

