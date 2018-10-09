# The Konnektor-IP
export KONNEKTOR_IP=10.33.128.4

export HEISE_IP=193.99.144.80
export WP2_ROOT_PASSWORD=123456

# The Konnektor-WAN-IP
#export KONNEKTOR_WAN_IP=192.168.3.41
export KONNEKTOR_WAN_IP=192.168.3.58

# The execution modus - DEVELOPMENT or EXECUTION_<VER_ABBR>
export EXECUTION_MODUS=EXECUTION_1_5_0_b209_CampusX

# The Konnektor-MNG-IP
export KONNEKTOR_MNG_IP=10.10.8.15

export VSDM_NEW_MOCKUP="yes"

# KT Sim von OL
#export CT_SIM=OL
export CT_SIM=FHI

#sqlite3 on Konnektor
export sqlite3_Konnektor=$(sshpass -p123456 ssh -p2222 root@10.10.8.15 'ls /opt/secure/current/extern/bin/ | grep sqlite3') &>/dev/null

# The variable indicates whether the FHI Card Terminal Simulation docker containers should be reset
# before each test case will be started.
# = {"yes"|"no"}
export RESTART_FHI_KT_SIMUL="yes"
export RESTART_FHI_KT_SIMUL="no"

#kontrolliere, ob die nötigen Zugriffsberechtigungen da sind 
export ACCESSCONTROL_RENEW="yes"
export ACCESSCONTROL_RENEW="no"

##############################################
### Management-IPs for the KT Simulations  ###
##############################################

export KT_A_MANAGEMENT_IP="10.60.5.200"
export KT_B_MANAGEMENT_IP="10.60.5.201"
export KT_C_MANAGEMENT_IP="10.60.5.202" 


# The local service of IP for the WP1 for communicating with the Konnektor 
export LOCAL_SERVICE_IP=10.10.8.6

# The Konnektor Type
export KONNEKTOR_TYPE=EB

# The Konnektor Version
export KONNEKTOR_VERSION="Telekom-Konnektor EBK (TKONEBK) in der Produktversion 1.5.0 - Build: 209 - Revision: 7c84f2fb54:2.2.4"

# The variable indicates whether the Konnektor-Version supports the flag MGM_LOGICAL_SEPARATION
# (see "gematik Spezifikation Konnektor", e.g. gemSpec_Kon_V4.11.1.pdf).
# = {"true"|"false"}
export LOGISCHE_TRENNUNG_UNTERSTUETZT="true"
#export LOGISCHE_TRENNUNG_UNTERSTUETZT="false"


if [ -x ~/java-oxygen/eclipse/eclipse ] || [ -x ~/eclipse/java-oxygen/eclipse/eclipse ]
then
	# Eclipse Oxygen
	ECLIPSE_PLUGINS_DIR=~/.p2/pool/plugins
else
if [ -x ~/eclipse/eclipse ]
then
	# Eclipse Mars
	ECLIPSE_PLUGINS_DIR=~/eclipse/plugins
else
	ECLIPSE_PLUGINS_DIR=~/unknown/plugins
fi
fi

ECLIPSE_PLUGINS_DIR=~/.p2/pool/plugins

LIB_FHI_CTSIM_CLIENT=\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/fhi-cardterminalsimulation/de.fraunhofer.fokus.cardterminalsimulation.client-0.10.0.jar


#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/konnektor-api/konnektor-api-2.0.0.424.jar
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/konnektor-api/konnektor-api-1.13.9.jar
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/konnektor-api/konnektor-api-1.13.10.jar
LIB_KONNEKTOR_API=\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/konnektor-api/konnektor-api-1.13.11.jar
#
export KONNEKTOR_TS_CLASS_PATH=\
../bin:\
$ECLIPSE_PLUGINS_DIR/org.junit_4.12.0.v201504281640/*:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/libthrift-0.9.3.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/json-simple-1.1.1.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/xercesImpl-2.9.0.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/guava-23.6-jre.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/gson-2.8.2.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/client-combined-3.12.0.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/byte-buddy-1.8.3.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-codec-1.10.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-exec-1.3.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-logging-1.2.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpclient-4.5.3.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpcore-4.4.6.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okhttp-3.9.1.jar:\
~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okio-1.13.0.jar:\
$ECLIPSE_PLUGINS_DIR/*:\
$LIB_KONNEKTOR_API:\
$LIB_FHI_CTSIM_CLIENT

## FHI KT-Sim 
##\
##$LIB_FHI_CTSIM_CLIENT


#/root/workspaceNeon/Web/lib/client-combined-3.12.0-sources.jar:\
#/root/workspaceNeon/Web/lib/gson-2.8.2.jar:\
#/root/workspaceNeon/Web/lib/gson-2.8.5.jar:\

#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/guava-angepasst.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/gson-2.8.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/client-combined-3.12.0-angepasst.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/byte-buddy-1.8.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-codec-1.10.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-exec-1.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-logging-1.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpclient-4.5.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpcore-4.4.6.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okhttp-3.9.1.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okio-1.13.0.jar:\






#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/guava-25.1-jre.jar:\

#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/guava-23.6-jre.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/client-combined-3.12.0-sources.jar:\

#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/gson-2.8.2.jar:\

#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-client-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-plugin-cardterminals-domain-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-plugin-cardterminals-client-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-client-plugin-base-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-shared-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/docker-client-8.8.1-shaded.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/spring-web-4.3.8.RELEASE.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/spring-core-4.3.8.RELEASE.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/spring-hateoas-0.23.0.RELEASE.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/spring-beans-4.3.8.RELEASE.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/jackson-core-2.8.8.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/jackson-databind-2.8.8.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/jackson-annotations-2.8.0.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/caffeine-2.3.5.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-plugin-konnektors-domain-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/tomf-plugin-konnektors-client-0.7.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/sqlite-jdbc-3.21.0.jar:\




##~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/json-simple-1.1.1.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/tomf/guava-21.0.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/byte-buddy-1.8.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/commons-codec-1.10.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/commons-exec-1.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/commons-logging-1.2.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/guava-23.6-jre.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/httpclient-4.5.3.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/httpcore-4.4.6.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/okhttp-3.9.1.jar:\
#~/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/libs/okio-1.13.0.jar:\

#
export KT_A_MAC=02\:42\:0a\:21\:80\:08
export KT_B_MAC=02\:42\:0a\:21\:80\:09
export KT_C_MAC=02\:42\:0a\:21\:80\:10
#export KT_A_MAC=ca\:4b\:63\:7a\:00\:01
#export KT_B_MAC=ca\:4b\:63\:7a\:00\:02
#export KT_C_MAC=ca\:4b\:63\:7a\:00\:03

MASTER_PASSWD=123456

export LOCALHOST_PASSWORD=$MASTER_PASSWD

# Call the Java function that restart the Konnektor
export KONNEKTOR_RESTART="java -cp $KONNEKTOR_TS_CLASS_PATH org.junit.runner.JUnitCore konnektor.testsuite.general.modules.KonnektorManagement.KonnektorRestartFunction"

# Networksegment for the LE Network
export LE_NETWORK=10.33.128.0/24

# The management/control IP of Remote Management Server behind SIS
#export REMOTE_MANAGEMENT_MGT_IP=10.60.5.72
export REMOTE_MANAGEMENT_MGT_IP=10.60.5.8

# The variable determines whether the object oriented version of the BasisKonfigurations should be used
# TODO: remove after it has been assured that the migration to the object oriented function was successfully accomplished
export BASIS_CONFIG_OBJECT_ORIENTATION=false

# SIS Network-Segment
export SIS_SEGMENT=11.222.0.0/24

# The SIS Test IP
export SIS_TEST_IP=11.222.0.3

# Networksegment for the LE Network
export TESTER_NODE=10.33.128.100

# The localhost-IP
export LOCALHOST_IP=10.33.128.100

# The localhost management/control IP
export LOCALHOST_SERVICE_CONTROL_IP=10.60.5.1

# The localhost-MAC
export LOCALHOST_MAC=70:5a:0f:47:28:eb

# konnektor root password
export LOCAL_PASSWORD=$MASTER_PASSWD

# The IP of the LAN DHCP Server
export LAN_DHCP_SERVER=10.33.128.1

# Temporal IP for WP1 to use while playing with the DHCP-Server of the test lab
#export WP1_TMP_IP=10.33.128.2
#export WP1_TMP_IP=10.33.128.4

# Temporal IP for WP2 to use while playing with the DHCP-Server of the test lab
#export WP2_TMP_IP=10.33.128.3
export WP2_TMP_IP=10.33.128.5

# Temporal IP for WP2 to use while playing with the DHCP-Server of the test lab
#export WP3_TMP_IP=10.33.128.4
export WP3_TMP_IP=10.33.128.6

# The MAC Adress of the Konnektor interface that is inside the LAN
#export KONNEKTOR_LAN_MAC=00:30:d6:15:9f:6a
export KONNEKTOR_LAN_MAC=00:30:d6:16:62:9b

# The MAC Adress of the Konnektor interface that is inside the WAN
#export KONNEKTOR_WAN_MAC=00:30:d6:15:7d:61
export KONNEKTOR_WAN_MAC=00:30:d6:16:42:1d

# The gematik.de IP for LAN-WAN testing
#export GEMATIK_IP=194.25.148.138
export GEMATIK_IP=158.181.50.96
export GEMATIK_URL=www.gematik.de

# TI root password
export TI_ROOT_PASSWORD=$MASTER_PASSWD

# SIS root password
export SIS_ROOT_PASSWORD=$MASTER_PASSWD

# The DNS test entry
export DNS_TI_TEST=_ntp._udp.vpn-zugd.telematik-test

# The management/control IP of the TI NTP 
export NTP_TI_IP=10.60.5.68

# The management/control IP of the TI DNS 
export DNS_TI_IP=10.60.5.69

# The management/control IP of the DNS PUBLIC
export DNS_PUBLIC_IP=10.60.5.5

# The management/control IP of the TI OCSP 
export OCSP_TI_IP=10.60.5.71

# The management/control IP of the Router-NAT 
export ROUTER_NAT_IP=10.60.5.10

# The management/control IP of the TI VSDM 
export VSDM_TI_IP=10.60.5.120

# The management/control IP of the TI INTERMEDIAER
export INTERMEDIAER_TI_IP=10.60.5.67

# The management/control IP of the TI KSR
export KSR_TI_IP=10.60.5.70



# Time for the DNS system to reload
export DNS_WAITING_TIME=120

# The IP address of the INTRANET_TEST_NODE (IP-Adresse von eth0 in meiner VM)
export INTRANET_TEST_NODE=10.33.128.100

# The path to the icmp mockup
export ICMP_SCAPY_MOCKUP=../icmp_scapy_mockup/icmp.py

# The management/control IP of the VPN TI Konzentrator
export VPN_TI_IP=10.60.5.3

# The management/control IP of the VPN SIS Konzentrator
export VPN_SIS_IP=10.60.5.4

# The management/control IP of the router
export ROUTER_IP=10.60.5.10

# Test domain name from DNSLEKTR
export DNS_LEKTR_NAME=gematik.de

# The time to wait for a VPN tunnel to establish or disconnect
export VPN_HANDLING_SLEEP_PERIOD=120

# The time which is given the Konnektor for a restart
export RESTART_TIMEOUT=260

# The time which is given the Konnektor for booting-up
export BOOTUP_TIMEOUT=260

# The path to the Konnektor-Log data
export KONNEKTOR_LOG_PATH="/tmp/konn/log"

# The path to the Konnektor-Log data
export KONNEKTOR_PASSWORD=$MASTER_PASSWD

# The Konnektor SSH-Port
export KONNEKTOR_PORT=2222

# Directory for the test data120
export TEST_DATA_DIR=./TestDaten

# An IP adress from the TI to use for the network Konnektor test cases
export NET_TI_ZENTRAL=172.24.1.65

# The timeout for the ICMP pings when testing network aspekts
export ICMP_TIMEOUT=60

#The timeout for telnet-connections
export TELNET_TIMEOUT=60

# The management/control IP of the VPN TI INTERMED
export INTERMED_SERVICE_CONTROL_IP=10.60.5.67

# The management IP of the VPN TI INTERMED
export INTERMED_SERVICE_IP=172.24.1.65

# The FQDN of the VPN TI INTERMED
export INTERMED_FQDN=intermed.vsdm.telematik-test

# The VSDM TI IP
export VSDM_TI_IP=172.28.0.2
# The management/control IP of the VPN TI VSDM Service
export VSDM_SERVICE_CONTROL_IP=10.60.5.120

# The service url of the VSDM Service
export VSDM_SERVICE_SERVICE_URL="http://localhost:8081"
# JAVA DEBUG PARAMETER
export JAVA_DEBUG_PARAMETER="-agentlib:jdwp=transport=dt_socket,server=n,suspend=y,address=8000"

# The management/control IP of the VPN TI OCSP Service
export OCSP_SERVICE_CONTROL_IP=10.60.5.71

# the path to store all certificates locally for printing later on
export PATH_TO_CERTIFICATES=../tmp_PKI

# The IP of the KSR service in the TI
export KSR_IP=172.24.1.1

# The path to the Bestandsnetze.xml on the KSR Server
export KSR_BESTANDSNETZE_SERVER_PATH=/var/www/html/TiNexus/Bestandsnetze.xml 	

# a test IP for Bestandsnetze to use for pinging etc.
export TEST_BESTANDSNETZE_IP=10.0.1.1

### NET_TI_ZENTRAL ############################

# An IP in NET_TI_ZENTRAL segment to use for network firewall/ping tests
export NET_TI_ZENTRAL_IP=172.24.2.1

### NET_TI_DEZENTRAL ##########################

# An IP in NET_TI_DEZENTRAL segment to use for network firewall/ping tests
export NET_TI_DEZENTRAL_IP=172.20.0.1

# The length of the network prefix of NET_TI_DEZENTRAL
export NET_TI_DEZENTRAL_PREFIX_LENGTH=14

### NET_TI_OFFENE_FD ###########################

# An IP in NET_TI_OFFENE_FD segment to use for network firewall/ping tests
export NET_TI_OFFENE_FD_IP=172.30.0.10

# The length of the network prefix of NET_TI_OFFENE_FD
export NET_TI_OFFENE_FD_PREFIX_LENGTH=16

# The machine for the NET_TI_OFFENE_FD --> it should be matching the IP from the config.properties
export NET_TI_OFFENE_FD_HOST=$NET_TI_OFFENE_FD_IP

### NET_TI_GESICHERTE_FD #######################

# An IP in NET_TI_GESICHERTE_FD segment to use for network firewall/ping tests
export NET_TI_GESICHERTE_FD_IP=172.28.0.10

# The length of the network prefix of NET_TI_GESICHERTE_FD
export NET_TI_GESICHERTE_FD_PREFIX_LENGTH=16

# The machine for the NET_TI_GESICHERTE_FD --> it should be matching the IP from the config.properties
export NET_TI_GESICHERTE_FD_HOST=$NET_TI_GESICHERTE_FD_IP

### NET_SIS ####################################

# An IP in NET_SIS segment to use for network firewall/ping tests
export NET_SIS_IP=172.16.0.101

# An IP from the SIS segment for testing
export NET_SIS_INTERNET_IP=$NET_SIS_IP

### ANLW_LEKTR_INTRANET_ROUTES: NET_INTRANET ###

# An IP in a network segment in ANLW_LEKTR_INTRANET_ROUTES to use for network firewall/ping tests
export NET_INTRANET_IP=10.33.122.1

# The length of the network prefix of NET_INTRANET
export NET_INTRANET_PREFIX_LENGTH=24

################################################

# The variable indicates whether all local network interfaces should be reset to default state
# before each test case will be started.
# Works on eth0, eth0:0, ...
# = {"yes"|"no"}
export RESET_NET_CFG="yes"
export RESET_NET_CFG="no"

# The variable indicates whether the Docker-TestEnvironment should be reset to default state
# before each test case will be started.
# = {"yes"|"no"}
export RESET_DOCKER_ENV="yes"
export RESET_DOCKER_ENV="no"
 
# The variable indicates whether the Konnektor should be reset to default state
# before each test case will be started.
# = {"yes"|"no"}
export RESET_KONNEKTOR="yes"
export RESET_KONNEKTOR="no"

# The variable indicates whether the TOMF-TestEnvironment should be reset to default state
# before each test case will be started.
# = {"yes"|"no"}
export RESET_TOMF_ENV="yes"
export RESET_TOMF_ENV="no"

export USE_TOMF="no"

# The variable indicates whether the network traffic will be save
export START_PCAP_LOGGING="yes"
export START_PCAP_LOGGING="no"

export START_PCAP_LOGGING_NTP="no"
export START_PCAP_LOGGING_DNS_TI="no"
export START_PCAP_LOGGING_DNS_PUBLIC="no"
export START_PCAP_LOGGING_OCSP="no"
export START_PCAP_LOGGING_ROUTER_NAT="no"
export START_PCAP_LOGGING_VSDM="no"
export START_PCAP_LOGGING_INTERMEDIAER="no"
export START_PCAP_LOGGING_KSR="no"

# The variable indicates to path to TOMF run script (the name for this script is shell) 
#export PATH_TO_TOMF="/root/temp/tomf/tomf-0.6.1"
export PATH_TO_TOMF="/root/tmp/tomf/tomf-0.7.2"
export LOCAL_PATH_TO_DB="/root/tmp/dbs2"

######################################################
### Management-IPs for the Workplaces in the LAN  ####
### Vital for the LAN-testcases with DHCP aspects ####
######################################################

# Currently no WP1 Management IP is needed since, we are on the very same host
export WP1_MANAGEMENT_IP=$LOCALHOST_SERVICE_CONTROL_IP

# Management IP for WP2
export WP2_MANAGEMENT_IP=10.60.5.90

# Management IP for WP3
export WP3_MANAGEMENT_IP=10.60.5.91

# The MAC Adress of the WP1 interface
export WP1_LAN_MAC=$LOCALHOST_MAC

# The MAC Adress of the WP2 interface
export WP2_LAN_MAC=08:00:27:0b:4f:69

# The MAC Adress of the WP3 interface
export WP3_LAN_MAC=


export WP2_LAN_IP=10.33.128.210
export WP3_LAN_IP=10.33.128.221

######################################################

export IntranetTestNextHop=10.33.122.221
export IntranetTestIpAddr=10.33.122.0
export IntranetTestSubNet=255.255.255.0

export IntranetTestNextHopIP=$KONNEKTOR_IP


#export

# The IP of the IAG router in row
export IAG_ROUTER_IN_ROW=192.168.3.1

# WP2 Management IP
export WP2_MNG_IP=10.60.5.90
# WP2 Intranet IP
export WP2_INTRANET_IP=10.33.122.210
# WP3 Management IP
export WP3_MNG_IP=10.60.5.91
# WP3 Management IP
export WP3_INTRANET_IP=10.33.122.221



export ANLW_AKTIVE_BESTANDSNETZE_WP=10.0.1.10

# The management IP for the machine from which NET_TI_DEZENTRAL-pings should be issued
export NET_TI_DEZENTRAL_MANAEMENT_IP=10.60.5.3


######################################################
function get_wp_lan_mac()
# MAC-Adressen in Docker-Umgebung werden dynamisch generiert
{
	WP_NAME="WP$1"
	case $WP_NAME in
	"WP2")
		WP_MANAGEMENT_IP=$WP2_MANAGEMENT_IP
		;;
	"WP3")
		WP_MANAGEMENT_IP=$WP3_MANAGEMENT_IP
		;;
	*)
		;;
	esac
	if [ -z "$WP_MANAGEMENT_IP" ]
	then
		LAN_MAC=""
		return 0
	fi
		
		LAN_MAC=`sshpass -p $MASTER_PASSWD ssh root@$WP_MANAGEMENT_IP "cat /sys/devices/virtual/net/eth0/address"`
}

 
######################################################

# IP for WP2 in a network segment in ANLW_LEKTR_INTRANET_ROUTES to use for network firewall/ping tests
export WP2_INTRANET_IP=10.33.122.210

# IP for WP3 in a network segment in ANLW_LEKTR_INTRANET_ROUTES to use for network firewall/ping tests
export WP3_INTRANET_IP=10.33.122.221

######################################################

# The IP Adress of the crl-ti
export CRL_TI_IP=10.60.5.32

# The IP Adress of sis-webserver 
export SIS_WEBSERVER_IP=10.60.5.92


# The expiration date of the TSL
#export TSL_GUELTIGKEITS_UEBERLAUFDATUM="2020-09-30 10:05:59.990"
export TSL_GUELTIGKEITS_UEBERLAUFDATUM="+10year"

#export NTP_INNER_IP=10.60.5.68
export NTP_INNER_IP=172.24.0.65
