#!/bin/bash
###################################################
### Script for Starting the TestCases ##############
### author: Nikolay Tcholtchev #####################
### Fraunhofer FOKUS ###############################
####################################################


# Global variables 
NUMBER_OF_ARGS=$#
ARGS=$*


######################################################
#### Function for initializing the test script #######
######################################################
function init {
	
	# load relevant configurations
	source ../testSteuerungsConfig.sh 
	
	# recursively set execution bit for all tc shell files
	echo $LOCALHOST_PASSWORD | sudo -S chmod -R ug+x TestFaelle/*
	
	chmod -R a+x VSDM
	
	# clean the temp dir 
	rm -rf ../tmp/*	2> /dev/null
	
	# Important for VSDM test cases
	unset VSDM_NEW_MOCKUP
	
	# move schemas to temp dir
	cp -r SoapXMLSchemata ../tmp/SoapXMLSchemata
	
	# print the Konnektor-Version
	echo ""
	echo "Konnektor-Version (Konfiguration in der Testumgebung):"
	echo $KONNEKTOR_VERSION
	echo ""
	
	# execute the test case in case it was not already successfully executed for the current EXECUTION_MODUS
	echo ""
	echo ""
	echo "Frühere Ausführungen von  $i für EXECUTION_MODUS="$EXECUTION_MODUS " werden geprüft ..."
	grep -r 'Verdict.*Gesamt.*:\s*PASSED' Protokollierung/$EXECUTION_MODUS*/*.txt | grep $i
	
	if [ $? -eq 0 ] 
	then 
		echo "Testfall $i wurde schon erfolgreich durchgeführt ..."
		
		# in case we are not in a run-plan 
		if [ -z $RUN_PLAN_MODUS ]
		then 
			# ask the tester whether an executed test case should be executed again
		
			while true
			do
				echo -n "Mögliche Eingaben: <W|w> - Weitermachen, <A|a> - Ausführung abbrechen: "
				read user_input
						
				if ( [ $user_input == "W" ] ||  [ $user_input == "w" ]  )
				then
					echo ""
					echo ""
					break
				fi 
						
				if ( [ $user_input == "A" ] ||  [ $user_input == "a" ]  )
				then
					echo ""
					echo "Die Ausführung wird beendet."
					echo ""
					echo ""
					exit
				fi
						
				echo "Die Eingabe \"$user_input\" kann nicht interpretiert werden"
				echo ""
			done
		fi
	fi 
	
	if [ ! -z $RUN_PLAN_MODUS ]
	then 
		# in case the RUN_PLAN_MODUS is set, which is the case when the script is started from within a RUN_PLAN 
		echo "RUN_PLAN_MODUS ist gesetzt!!!"
		echo "Der EXECUTION_MODUS wird auf "$RUN_PLAN_MODUS" gesetzt"
		EXECUTION_MODUS=$RUN_PLAN_MODUS
	fi
	
	
	echo "Test-System Execution Modus:" $EXECUTION_MODUS	
	
	# check if the directory for log execution indeed exiss	
	if [ ! -d  Protokollierung/$EXECUTION_MODUS ]; then
		#		echo "Das eingestellte Protokollierungsverzeichnis \""Protokollierung/$EXECUTION_MODUS"\" existiert nicht!!!"
		#		echo "Leaving ..."
		#		exit 1
		mkdir -p Protokollierung/$EXECUTION_MODUS ;
	fi
	
	# make sure that the folder Protokollierung can be updated
	echo $LOCALHOST_PASSWORD | sudo -S chmod -R ug+w Protokollierung/*
	
	echo "Speichere Protokolle unter "Protokollierung/$EXECUTION_MODUS
	
	# clean up any files from previous FAILED executions
	echo ""
	echo "Entferne Artefakte aus früheren Failed-Ausführungen für $i ..." 
	echo "rm -f Protokollierung/$EXECUTION_MODUS/$i\_JIRA.txt"
	rm -f Protokollierung/$EXECUTION_MODUS/$i\_JIRA.txt
	echo "rm -f Protokollierung/$EXECUTION_MODUS/$i\_konnLog.tar.gz"
	rm -f Protokollierung/$EXECUTION_MODUS/$i\_konnLog.tar.gz
	echo ""
	
	# clean up any Interface Trace files from previous executions
	echo ""
	echo "Entferne Interface Traces aus früheren Ausführungen für $i ..." 
    echo "rm -f Protokollierung/$EXECUTION_MODUS/$i*_Server_Traffic.*"
	rm -f Protokollierung/$EXECUTION_MODUS/$i*_Server_Traffic.*
		
	
	###
	### Apply these 5 steps to reset the whole test environment (Network, Docker, Konnektor):
	###
	
	### Step 1 ###
	
	# This script ensures that we can connect to the Konnektor over
	# the management/control network interface.
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_NET_CFG
	HelperScripts/reset_all_local_Network_Interfaces.sh
	echo ""
	
	### Step 2 ###
	
	# perform some basic arrangements, i.e.
	#  - GlobalData verify
	#  - clear system-protocol of konnektor (via Thrift) 
	#  - reset the trace logfiles in 'KONNEKTOR_LOG_PATH' log-directory
	java -cp $KONNEKTOR_TS_CLASS_PATH  konnektor.testsuite.general.utils.KonnektorInit
	echo ""
	
	### Step 3 ###
	
	# This script stops the Konnektor.
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_KONNEKTOR
	#HelperScripts/stop_Konnektor.sh
	echo ""
	
	### Step 4 ###

	# This script start tomf
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_TOMF_ENV
	HelperScripts/reset_TOMF_TestEnvironment.sh
	echo ""
	
	### Step 5 ###
	
	# This script resets the Docker-TestEnvironment.
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_DOCKER_ENV
	HelperScripts/reset_Docker_TestEnvironment.sh
	echo ""
	
	### Step 6 ###
	
	# This script resets the RMS VM.
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_RMSOVA_ENV
	HelperScripts/resetRMSova.sh
	echo ""
	
	### Step 7 ###
	#	sshpass -p123456 ssh root@10.10.8.15 -p2222 "tar -cvf KonnLog.tar /tmp/konn/log"
	#sshpass -p123456 ssh root@10.10.8.15 -p2222  gzip KonnLog.tar
	#sshpass -p123456 scp -P 2222 root@10.10.8.15:~/KonnLog.tar.gz /root/tmp/logging/"$i"_"$EXECUTION_MODUS"_begin_KonnLog.tar.gz
	#sshpass -p123456 ssh root@10.10.8.15 -p2222  rm -f KonnLog.tar
	#sshpass -p123456 ssh root@10.10.8.15 -p2222  rm -f ~/KonnLog.tar.gz
	
	# This script resets the Konnektor to initial state.
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESET_KONNEKTOR
	HelperScripts/reset_Konnektor.sh
	if [ $? -eq 0 ]
	then
		FORCE_APPEND_LOGS="no"
	else
		FORCE_APPEND_LOGS="yes"
	fi
	FORCE_APPEND_LOGS="yes"
	echo ""
	# tmp
	#FORCE_APPEND_LOGS="yes"
	# !tmp


	### Step 8 ###
	# Rest card terminals
	java -cp $KONNEKTOR_TS_CLASS_PATH  konnektor.testsuite.general.utils.KTSimInit
		
	### Step 9 ###
	# This script restart FHI-Kartensimulation-Services for ct-a, ct-b und ct-c   .
	# There is an environment variable in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $RESTART_FHI_KT_SIMUL
	HelperScripts/restart_FHI_CardSimul.sh
	echo ""
	
	### Step 10 ###

	# This script start the Logging for ...  .
	# There are environment variables in ../testSteuerungsConfig.sh
	# to control the execution:
	#   $START_PCAP_LOGGING
	#   $ALWAYS_SAVE_PCAP
	#   $PCAP_VERBOSE_CONF
	HelperScripts/start_pcap_Protokollierung.sh
	echo ""
	
	if [ "w$ACCESSCONTROL_RENEW" = "wyes" ]
	then
	 	zugriffsberechtigungen
	fi
	
}



######################################################
#### Function for running all the test cases #########
######################################################
function runAll {
	echo "Not implemented yet ...";
}


######################################################
#### Function for running a single test case #########
######################################################
function runTestCase {
	
	# get the test case name
    testCaseName=$1;
    
  	# switch the use test case name
    case $testCaseName in
	
	"aaaa") echo "Executing test case \"aaaa\" ..."
		TestFaelle/aaaa.sh    2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"Zeit") echo "Executing test case Zeit ..."
		TestFaelle/zeit.sh
	;;
	
	"TIP1_A_4840_03") echo "Executing test case TIP1-A_4840-03 Ausloesen der durchzufuehrenden Erprobungs-Updates (interaktiv)"
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4840_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5152_01") echo "Executing test case TIP1-A_5152-01 Aktualisieren der Infrastrukturinformationen aus der TI"
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_5152_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4758_01") echo "Executing test case TIP1-A_4758-01 TUC_KON_304 Netzwerk-Routen einrichten"
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4758_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4838_02") echo "Executing test case TIP1-A_4838-02 TUCs in insichtnahme in Update-Informationen - Konnektor-Firmware (interaktiv)..."
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4838_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5336_01") echo "Executing test case "GS-A_5336-01 Zertifikatspruefung nach Ablauf TSL-Graceperiod " ..."
	TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/GS_A_5336_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4751_02") echo "Executing test case "TIP1-A_4751-01 TUCs in Reagiere auf LAN_IP_Changed - LAN_CLIENT_RENEW" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4751_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4752_01") echo "Executing test case "TIP1-A_4752-01 TUCs in Reagiere auf WAN_IP_Changed - Event ANLWWAN-IP_CHANGED" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4752_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4752_02") echo "Executing test case "TIP1-A_4752-02 TUCs in der Bootup-Phase" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4752_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4508_01") echo "Executing test case "TIP1-A_4508-01 TUCs in der Bootup-Phase" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4508_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4503_01") echo "Executing test case "TIP1-A_4503-01 Verpflichtung zur Nutzung von gSMC-K" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4503_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4503_02") echo "Executing test case "TIP1-A_4503-02 Nutzung von gSMC-K für Schlüsselmaterial" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4503_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4505_01") echo "Executing test case "TIP1-A_4505-01 Schutz vor physischer Manipulation gSMC-K \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4505_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4506_01") echo "Executing test case "TIP1-A_4506-01 Initiale Identitaeten der gSMC-K - ID.NK.VPN" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4506_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4506_02") echo "Executing test case "TIP1-A_4506-02 Initiale Identitaeten der gSMC-K - ID.AK.AUT" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4506_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4506_03") echo "Executing test case "TIP1-A_4506-03 Initiale Identitaeten der gSMC-K - ID.SAK.AUT" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4506_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4508_02") echo "Executing test case "TIP1-A_4508-02 BOOTUP-BOOTUP_COMPLETE" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4508_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4508_03") echo "Executing test case "TIP1-A_4508-03 Bootup-Phase trotz Fehler abschliessen" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4508_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_01") echo "Executing test case "TIP1-A_4509-01 EC_Connector_Software_Out_Of_Date" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_02") echo "Executing test case "TIP1-A_4509-02 EC_Time_Sync_not_Successful" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_03") echo "Executing test case "TIP1-A_4509-03 EC_TSL_Update_Not_Successful" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_04") echo "Executing test case "TIP1-A_4509-04 EC_TSL_Expiring" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_05") echo "Executing test case "TIP1-A_4509-05 EC_TSL_Trust_Anchor_Expiring" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_06") echo "Executing test case "TIP1-A_4509-06 EC_CRL_Expiring" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_07") echo "Executing test case "TIP1-A_4509-07 EC_Time_Sync_Pending_Warning" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_08") echo "Executing test case "TIP1-A_4509-08 EC_TSL_Out_Of_Date_Within_Grace_Period" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_09") echo "Executing test case "TIP1-A_4509-09 EC_No_VPN_TI_Connection" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_10") echo "Executing test case "TIP1-A_4509-10 EC_No_VPN_SIS_Connection" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_11") echo "Executing test case "TIP1-A_4509-11 EC_No_Online_Connection" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_12") echo "Executing test case "TIP1-A_4509-12 EC_IP_Adresses_Not_Available" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4509_13") echo "Executing test case "TIP1-A_4509-13 Kritische Betriebszustände" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4509_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_01") echo "Executing test case "TIP1-A_4510-01 EC_Secure_KeyStore_Not_Available" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_02") echo "Executing test case "TIP1-A_4510-02 EC_TSL_Trust_Anchor_Out_of_Date" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_03") echo "Executing test case "TIP1-A_4510-03 EC_Time_Sync_Pending_Critical" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_04") echo "Executing test case "TIP1-A_4510-04 EC_Time_Difference_Intolerable" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_05") echo "Executing test case "TIP1-A_4510-05 EC_CRL_Out_of_Date" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4510_06") echo "Executing test case "TIP1-A_4510-06 EC_TSL_Out_Of_Date_Beyond_Grace_Period" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4510_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4512_01") echo "Executing test case "TIP1-A_4512-01 Ereignis bei Aenderung des Betriebszustandes" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4512_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4513_01") echo "Executing test case "TIP1-A_4513-01 Betriebszustaende anzeigen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4513_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4513_02") echo "Executing test case "TIP1-A_4513-02 Alle Betriebszustaende anzeigen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4513_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4513_03") echo "Executing test case "TIP1-A_4513-03 Fehlerzustände zurücksetzen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4513_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4514_01") echo "Executing test case "TIP1-A_4514-01 Verfuegbarkeit einer TLS Schnittstelle" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4514_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4515_01") echo "Executing test case "TIP1-A_4515-01 TLS und der Dienstverzeichnisdienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4515_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4515_02") echo "Executing test case "TIP1-A_4515-02 TLS-Verbindung immer möglich" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4515_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4516_01") echo "Executing test case "TIP1-A_4516-01 Basic Authentication" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4516_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4516_02") echo "Executing test case "TIP1-A_4516-02 Certificate Authentication - Gutfall" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4516_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4516_03") echo "Executing test case "TIP1-A_4516-03 Certificate Authentication - Zertifikat ungueltig" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4516_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4516_04") echo "Executing test case "TIP1-A_4516-04 Certificate Authentication - Zertifikat abgelaufen" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4516_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4516_05") echo "Executing test case "TIP1-A_4516-05 Certificate Authentication - Unbekanntes Zertifikat" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4516_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4517_01") echo "Executing test case "TIP1-A_4517-01 Schluessel und X.509-Zertifikate fuer Client-Authentisierung erzeugen und exportieren" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4517_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4517_02") echo "Executing test case "TIP1-A_4517-02 X.509-Zertifikate fuer Client-Authentisierung importieren" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4517_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4518_01") echo "Executing test case "TIP1-A_4518-01 Konfiguration der Anbindung Clientsysteme \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4518_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4518_02") echo "Executing test case "TIP1-A_4518-02 Konfiguration der Anbindung Clientsysteme" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4518_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4519_01") echo "Executing test case "TIP1-A_4519-01 CardService konform zu [BasicProfile1.2]" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4519_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4519_02") echo "Executing test case "TIP1-A_4519-02 CardTerminalService konform zu [BasicProfile1.2]" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4519_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4519_03") echo "Executing test case "TIP1-A_4519-03 CertificateService konform zu [BasicProfile1.2]" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4519_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4519_04") echo "Executing test case "TIP1-A_4519-04 EventService konform zu [BasicProfile1.2]" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4519_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4520_01") echo "Executing test case "TIP1-A_4520-01 Bildung von Fehler-Trace-Strukturen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4520_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4521_01") echo "Executing test case "TIP1-A_4521-01 Protokollierung von Fehlern inkl.Trace-Struktur \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4521_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4597_01") echo "Executing test case "TIP1-A_4597-01 Unterstuetzung von Missbrauchserkennungen" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4597_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4707_01") echo "Executing test case "TIP1-A_4707-01 Betrieb in Test- und Referenzumgebung" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4707_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4981_01") echo "Executing test case "TIP1-A_4981-01 Steuerung der Betriebsumgebung via gSMC-K \(RU-TU\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4981_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4981_02") echo "Executing test case "TIP1-A_4981-02 Steuerung der Betriebsumgebung via gSMC-K \(PU\) \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4981_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4982_01") echo "Executing test case "TIP1-A_4982-01 Anzeige der Betriebsumgebung \(RU-TU\) \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4982_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4982_02") echo "Executing test case "TIP1-A_4982-02 Keine Anzeige der Betriebsumgebung \(PU\) \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_4982_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5009_01") echo "Executing test case "TIP1-A_5009-01 TLS-Server-Authentifizierung ohne Client-Authentifizierung" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5009_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5009_02") echo "Executing test case "TIP1-A_5009-02 TLS-Server-Authentifizierung mit Client-Authentifizierung" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5009_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5009_03") echo "Executing test case "TIP1-A_5009-03 TLS-Server-Authentifizierung mit HTTP Basic Authentication" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5009_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5009_04") echo "Executing test case "TIP1-A_5009-04 TLS deaktiviert" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5009_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5058_01") echo "Executing test case "TIP1-A_5058-01 gematik-SOAP-Fault" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5058_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5058_02") echo "Executing test case "TIP1-A_5058-02 gematik-SOAP-Fault-Struktur" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5058_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5401_01") echo "Executing test case "TIP1-A_5401-01 Parallele Nutzbarkeit Dienstverzeichnisdienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5401_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5401_02") echo "Executing test case "TIP1-A_5401-02 Parallele Nutzbarkeit Kartenterminaldienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5401_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5401_03") echo "Executing test case "TIP1-A_5401-03 Parallele Nutzbarkeit Kartendienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5401_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5401_04") echo "Executing test case "TIP1-A_5401-04 Parallele Nutzbarkeit Systeminformationsdienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5401_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5401_05") echo "Executing test case "TIP1-A_5401-05 Parallele Nutzbarkeit Zertifikatsdienst" ..."
		TestFaelle/01_Paket1/01_01_Uebergreifende_Festlegungen/01_01_01_Uebergreifende_Tests/TIP1_A_5401_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4594_01") echo "Executing test case "TIP1-A_4594-01 Richtung bei Verbindungsaufbau des Systeminformationsdienstes" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4594_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4595_01") echo "Executing test case "TIP1-A_4595-01 Gesicherte Uebertragung von Ereignissen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4595_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4596_01") echo "Executing test case "TIP1-A_4596-01 Nachrichtenaufbau und -kodierung des Systeminformationsdienstes" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4596_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_01") echo "Executing test case "TIP1-A_4598-01 TUC_KON_256 -Systemereignis absetzen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_02") echo "Executing test case "TIP1-A_4598-02 TUC_KON_256 -Systemereignis absetzen- XPath-Filter" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_03") echo "Executing test case "TIP1-A_4598-03 TUC_KON_256 -Systemereignis absetzen- BOOTUP-COMPLETE" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4599_01") echo "Executing test case "TIP1-A_4599-01 TUC_KON_252 -Liefere KT_Liste- Mandantweit" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4599_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4599_02") echo "Executing test case "TIP1-A_4599-02 TUC_KON_252 -Liefere KT_Liste- Arbeitsplatz" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4599_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4599_03") echo "Executing test case "TIP1-A_4599-03 TUC_KON_252 -Liefere KT_Liste- Verfuegbarkeit der KTs" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4599_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4604_01") echo "Executing test case "TIP1-A_4604-01 Operation GetCardTerminals - Mandantweit" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4604_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4604_02") echo "Executing test case "TIP1-A_4604-02 Operation GetCardTerminals - Arbeitsplatz" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4604_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4604_03") echo "Executing test case "TIP1-A_4604-03 Operation GetCardTerminals - Ohne mandant-wide" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4604_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_01") echo "Executing test case "TIP1-A_4600-01 TUC_KON_253 ohne optionale Parameter" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_02") echo "Executing test case "TIP1-A_4600-02 TUC_KON_253 mit Angabe der Arbeitsplatz ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_03") echo "Executing test case "TIP1-A_4600-03 TUC_KON_253 mit Kartenterminal ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_04") echo "Executing test case "TIP1-A_4600-04 TUC_KON_253 mit CardType" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_05") echo "Executing test case "TIP1-A_4600-05 TUC_KON_253 Fehler 4096" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4600_06") echo "Executing test case "TIP1-A_4600-06 TUC_KON_253 mit Kartenterminal ID und Slot ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4600_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_01") echo "Executing test case "TIP1-A_4602-01 TUC_KON_254 -Liefere Ressourcendetails- Konnektorstatus" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_02") echo "Executing test case "TIP1-A_4602-02 TUC_KON_254 -Liefere Ressourcendetails- Kartenterminal-ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_03") echo "Executing test case "TIP1-A_4602-03 TUC_KON_254 -Liefere Ressourcendetails- Kartenterminal-ID ohne Zugriff" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_04") echo "Executing test case "TIP1-A_4602-04 TUC_KON_254 -Liefere Ressourcendetails- Kartenterminal-ID und SlotID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_05") echo "Executing test case "TIP1-A_4602-05 TUC_KON_254 -Liefere Ressourcendetails- CardHandle" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_06") echo "Executing test case "TIP1-A_4602-06 TUC_KON_254 -Liefere Ressourcendetails- ICCSN" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_07") echo "Executing test case "TIP1-A_4602-07 TUC_KON_254 mit Kartenterminal-ID - Fehler 4096" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_08") echo "Executing test case "TIP1-A_4602-08 TUC_KON_254 mit Kartenterminal-ID und SlotID - Fehler 4096" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_09") echo "Executing test case "TIP1-A_4602-09 TUC_KON_254 mit Kartenterminal-ID und SlotID - Fehler 4097" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_10") echo "Executing test case "TIP1-A_4602-10 TUC_KON_254 mit Kartenterminal-ID und SlotID - Fehler 4098" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_11") echo "Executing test case "TIP1-A_4602-11 TUC_KON_254 mit ICCSN - Fehler 4099" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4602_12") echo "Executing test case "TIP1-A_4602-12 TUC_KON_254 mit CardHandle - Fehler 4101" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4602_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_01") echo "Executing test case "TIP1-A_4605-01 Operation GetCards - Mandantenweit" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_02") echo "Executing test case "TIP1-A_4605-02 Operation GetCards - Arbeitsplatzbezogen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_03") echo "Executing test case "TIP1-A_4605-03 Operation GetCards - Kartenterminal ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_04") echo "Executing test case "TIP1-A_4605-04 Operation GetCards - Slot ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_05") echo "Executing test case "TIP1-A_4605-05 Operation GetCards -Kartentyp" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4605_06") echo "Executing test case "TIP1-A_4605-06 Operation GetCards - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4605_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_01") echo "Executing test case "TIP1-A_4608-01 Operation Subscribe" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_02") echo "Executing test case "TIP1-A_4608-02 Operation Subscribe - XPath-Filter" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_03") echo "Executing test case "TIP1-A_4608-03 Operation Subscribe - High-Level-Topic" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_04") echo "Executing test case "TIP1-A_4608-04 Operation Subscribe - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4609_01") echo "Executing test case "TIP1-A_4609-01 Operation Unsubscribe - SubscriptionID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4609_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4609_02") echo "Executing test case "TIP1-A_4609-02 Operation Unsubscribe - EventTo" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4609_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4609_03") echo "Executing test case "TIP1-A_4609-03 Operation Unsubscribe - Fehler 4102" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4609_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4609_04") echo "Executing test case "TIP1-A_4609-04 Operation Unsubscribe - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4609_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_01") echo "Executing test case "TIP1-A_4610-01 Operation GetSubscription - Mandantenweit" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_02") echo "Executing test case "TIP1-A_4610-02 Operation GetSubscription - Arbeitsplatzbezogen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_03") echo "Executing test case "TIP1-A_4610-03 Operation GetSubscription - Spezifische Subscription" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_04") echo "Executing test case "TIP1-A_4610-04 Operation GetSubscription - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_05") echo "Executing test case "TIP1-A_4610-05 Operation GetSubscription - Fehler 4102" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4612_01") echo "Executing test case "TIP1-A_4612-01 Maximale Anzahl an Subscriptions" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4612_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4613_01") echo "Executing test case "TIP1-A_4613-01 Initialisierung Subscriptions-Liste beim Bootup" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4613_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5112_01") echo "Executing test case "TIP1-A_5112-01 Operation RenewSubscriptions" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_5112_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5112_02") echo "Executing test case "TIP1-A_5112-02 Operation RenewSubscriptions - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_5112_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5112_03") echo "Executing test case "TIP1-A_5112-03 Operation RenewSubscriptions - Ungueltige SubscriptionIDs" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_5112_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5536_01") echo "Executing test case "TIP1-A_5536-01 Connector Event Transport Protocol ueber TCP \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_5536_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4603_01") echo "Executing test case "TIP1-A_4603-01 Basisanwendung Systeminformationsdienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4603_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_01") echo "Executing test case "TIP1-A_4607-01 GetResourceInformation - Konnektorstatus" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_02") echo "Executing test case "TIP1-A_4607-02 GetResourceInformation - Kartenterminal-ID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_03") echo "Executing test case "TIP1-A_4607-03 GetResourceInformation - Kartenterminal-ID ohne Zugriff" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_04") echo "Executing test case "TIP1-A_4607-04 Get ResourceInformation - Kartenterminal-ID und SlotID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_05") echo "Executing test case "TIP1-A_4607-05 GetResourceInformation - CardHandle" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_06") echo "Executing test case "TIP1-A_4607-06 GetResourceInformation - ICCSN" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4607_07") echo "Executing test case "TIP1-A_4607-07 Get ResourceInformation - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4607_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4611_01") echo "Executing test case "TIP1-A_4611-01 Konfigurationswerte des Systeminformationsdienstes" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4611_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4604_04") echo "Executing test case "TIP1-A_4604-04 Operation GetCardTerminals - Fehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4604_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_05") echo "Executing test case "TIP1-A_4608-05 Operation Subscribe - TerminationTime-Update" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4608_06") echo "Executing test case "TIP1-A_4608-06 Operation Subscribe - Erloeschen einer Subscription" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4608_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4610_06") echo "Executing test case "TIP1-A_4610-06 Operation GetSubscription - Mandantenweit SubscriptionID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4610_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4612_02") echo "Executing test case "TIP1-A_4612-02 Maximale Anzahl an Subscriptions - Renewal und Loeschen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4612_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5112_04") echo "Executing test case "TIP1-A_5112-04 Operation RenewSubscriptions - abgelaufene Subscription" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_5112_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_04") echo "Executing test case "TIP1-A_4598-04 TUC_KON_256 -Systemereignis absetzen - mehrere Abonnenten" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_05") echo "Executing test case "TIP1-A_4598-05 TUC_KON_256 - DoDisp und NoLog" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_06") echo "Executing test case "TIP1-A_4598-06 TUC_KON_265 - NoDsp und NoLog" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_07") echo "Executing test case "TIP1-A_4598-07 TUC_KON_256 - NoDisp und DoLog" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4598_08") echo "Executing test case "TIP1-A_4598-08 TUC_KON_256 - Übergeordnetes Topic" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_01_Systeminformationsdienst/01_02_01_Systeminformationsdienst/TIP1_A_4598_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4708_01") echo "Executing test case "TIP1-A_4708-01 Protokollierungsfunktion" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4708_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4708_02") echo "Executing test case "TIP1-A_4708-02 Unterschiedliche Protokolle" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4708_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4708_03") echo "Executing test case "TIP1-A_4708-03 Persistieren der Protokolleintraege" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4708_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4710_01") echo "Executing test case "TIP1-A_4710-01 Protokollierung personenbezogener und medizinischer Daten \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4710_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4712_01") echo "Executing test case "TIP1-A_4712-01 LOG_SUCCESSFUL_CRYPTO_OPS" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4712_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4713_01") echo "Executing test case "TIP1-A_4713-01 Herstellerspezifische Systemprotokollierung \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4713_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4714_01") echo "Executing test case "TIP1-A_4714-01 Art der Protokollierung \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4714_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4715_01") echo "Executing test case "TIP1-A_4715-01 TUC_KON_271 - Systemprotokoll" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4715_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4715_02") echo "Executing test case "TIP1-A_4715-02 TUC_KON_271 - Sicherheitsprotokoll" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4715_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4715_03") echo "Executing test case "TIP1-A_4715-03 TUC_KON_271 - Performance-Protokoll" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4715_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4715_04") echo "Executing test case "TIP1-A_4715-04 TUC_KON_271 - VSDM Protokolle" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4715_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4715_05") echo "Executing test case "TIP1-A_4715-05 TUC_KON_271 VSDM - Sicherheitsprotokoll aus Fachmodul" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4715_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4716_01") echo "Executing test case "TIP1-A_4716-01 Einsichtnahme in Protokolle \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4716_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4716_02") echo "Executing test case "TIP1-A_4716-02 Exportieren von Protokollen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4716_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4716_03") echo "Executing test case "TIP1-A_4716-03 Integrität des Sicherheitsprotokolls \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4716_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4716_04") echo "Executing test case "TIP1-A_4716-04 Löschen von Protokollen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4716_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_01") echo "Executing test case "TIP1-A_4717-01 LOG_LEVEL_SYSLOG = Information \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_02") echo "Executing test case "TIP1-A_4717-02 LOG_LEVEL_SYSLOG = Warning" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_03") echo "Executing test case "TIP1-A_4717-03 LOG_LEVEL_SYSLOG = Error" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_04") echo "Executing test case "TIP1-A_4717-04 LOG_LEVEL_SYSLOG = Fatal" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_05") echo "Executing test case "TIP1-A_4717-05 LOG_DAYS \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4717_06") echo "Executing test case "TIP1-A_4717-06 FM_VSDM_LOG_DAYS \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4717_11") echo "Executing test case "TIP1-A_4717-11 FM_VSDM_LOG_LEVEL = Debug \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4717_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4718_01") echo "Executing test case "TIP1-A_4718-01 TUC_KON_272 -Initialisierung Protokollierungsdienst-" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4718_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4996_01") echo "Executing test case "TIP1-A_4996-01 Hinweis auf neue Sicherheitsprotokolleintraege \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_02_Protokollierungsdienst/01_02_02_Protokollierungsdienst/TIP1_A_4996_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4522_02") echo "Executing test case "TIP1-A_4522-02 Informationsmodell \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4522_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4522_03") echo "Executing test case "TIP1-A_4522-03 Persistieren des Informationsmodells \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4522_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4522_04") echo "Executing test case "TIP1-A_4522-04 Beachtung von Constraints zu Eindeutigkeit und Mandanten \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4522_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4522_05") echo "Executing test case "TIP1-A_4522-05 Beachtung von Constraints zu Remote-PIN \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4522_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4523_01") echo "Executing test case "TIP1-A_4523-01 Reaktion auf Änderungen am persistenten Informationsmodell" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4523_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4523_02") echo "Executing test case "TIP1-A_4523-02 Reaktion auf Änderungen am transienten Informationsmodell" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4523_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_01") echo "Executing test case "TIP1-A_4524-01 TUC_KON_000 - Gutfall und Fehler 4015" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_02") echo "Executing test case "TIP1-A_4524-02 TUC_KON_000 - Fehler 4021" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_03") echo "Executing test case "TIP1-A_4524-03 TUC_KON_000 - Fehler 4008" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_04") echo "Executing test case "TIP1-A_4524-04 TUC_KON_000 - Fehler 4015" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_05") echo "Executing test case "TIP1-A_4524-05 TUC_KON_000 - Fehler 4003" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_06") echo "Executing test case "TIP1-A_4524-06 TUC_KON_000 - Fehler 4004 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_07") echo "Executing test case "TIP1-A_4524-07 TUC_KON_000 - Fehler 4005 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_08") echo "Executing test case "TIP1-A_4524-08 TUC_KON_000 - Fehler 4006 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_09") echo "Executing test case "TIP1-A_4524-09 TUC_KON_000 - Fehler 4007 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_10") echo "Executing test case "TIP1-A_4524-10 TUC_KON_000 - Fehler 4009 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_11") echo "Executing test case "TIP1-A_4524-11 TUC_KON_000 - Fehler 4010" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_12") echo "Executing test case "TIP1-A_4524-12 TUC_KON_000 - Fehler 4011" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_13") echo "Executing test case "TIP1-A_4524-13 TUC_KON_000 - Fehler 4012" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_14") echo "Executing test case "TIP1-A_4524-14 TUC_KON_000 - Fehler 4013" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_15") echo "Executing test case "TIP1-A_4524-15 TUC_KON_000 - Fehler 4014" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_16") echo "Executing test case "TIP1-A_4524-16 TUC_KON_000 - Fehler 4016" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_17") echo "Executing test case "TIP1-A_4524-17 TUC_KON_000 - Fehler 4017" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_17.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_18") echo "Executing test case "TIP1-A_4524-18 TUC_KON_000 - Fehler 4019" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_18.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4524_19") echo "Executing test case "TIP1-A_4524-19 TUC_KON_000 - Fehler 4020" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4524_19.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4525_01") echo "Executing test case "TIP1-A_4525-01 Initialisierung Zugriffsberechtigungsdienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4525_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4526_01") echo "Executing test case "TIP1-A_4526-01 Bearbeitung Mandant \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4526_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4526_02") echo "Executing test case "TIP1-A_4526-02 Bearbeitung Clientsystem \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4526_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4526_03") echo "Executing test case "TIP1-A_4526-03 Bearbeitung Arbeitsplatz \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4526_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4522_01") echo "Executing test case "TIP1-A_4522-01 999 Mandanten" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_03_Zugriffsberechtigungsdienst/01_02_03_Zugriffsberechtigungsdienst/TIP1_A_4522_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4528_01") echo "Executing test case "TIP1-A_4528-01 Bereitstellen des Dienstverzeichnisdienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4528_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4528_02") echo "Executing test case "TIP1-A_4528-02 Bereitstellen des Dienstverzeichnisdienst - TLS verpflichtend" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4528_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4528_03") echo "Executing test case "TIP1-A_4528-03 Bereitstellen des Dienstverzeichnisdienst - http durch ANCL_DVD_OPEN" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4528_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4529_01") echo "Executing test case "TIP1-A_4529-01 Formatierung der Ausgabedatei" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4529_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4532_01") echo "Executing test case "TIP1-A_4532-01 Schnittstelle der Basisanwendung Dienstverzeichnisdienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4532_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4532_02") echo "Executing test case "TIP1-A_4532-02 Schnittstelle der Basisanwendung Dienstverzeichnisdienst - HTTP-Fehler 404" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4532_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;	

	"TIP1_A_5530_01") echo "Executing test case "TIP1-A_5530-01  - - NET_TI_OFFENE_FD - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5530_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5530_02") echo "Executing test case "TIP1-A_5530-02 - - Kommunikation mit NET_TI_OFFENE_FD -Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5530_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;


	"TIP1_A_4533_01") echo "Executing test case "TIP1-A_4533-01 Dienstverzeichnisdienst initialisieren" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_05_Dienstverzeichnisdienst/01_02_05_Dienstverzeichnisdienst/TIP1_A_4533_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4534_01") echo "Executing test case "TIP1-A_4534-01 Kartenterminals nach eHealth-KT-Spezifikation" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4534_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4544_03") echo "Executing test case "TIP1-A_4544-03 KT-Statusanpassung bei Ende eines Updatevorgangs - KT nicht aktiv \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4544_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	"TIP1_A_5530_01") echo "Executing test case "TIP1-A_5530-01  - - NET_TI_OFFENE_FD - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5530_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	"TIP1_A_4536_01") echo "Executing test case "TIP1-A_4536-01 TLS-Verbindung zu Kartenterminals halten - GET STATUS" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4536_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4537_02") echo "Executing test case "TIP1-A_4537-02 KT-Statusanpassung bei Beendigung o. Timeout einer Netzwerkverb. TERMINAL SIGN OFF" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4537_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4537_03") echo "Executing test case "TIP1-A_4537-03 KT-Statusanpassung bei Beendigung o.Timeout einer Netzwerkverb. - Netzwerkstoerung" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4537_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4538_01") echo "Executing test case "TIP1-A_4538-01 Wiederholter Verbindungsversuch zu den KTs" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4538_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4539_01") echo "Executing test case "TIP1-A_4539-01 Robuster Kartenterminaldienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4539_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4539_02") echo "Executing test case "TIP1-A_4539-02 Robuster Kartenterminaldienst - Andere Slots" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4539_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4540_03") echo "Executing test case "TIP1-A_4540-03 Reaktion auf KT-Service-Announcement bei nicht unterstützter KT-Version" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4540_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5413_01") echo "Executing test case "TIP1-A_5413-01 EjectCard - CtID und SlotID" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5413_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_02") echo "Executing test case "TIP1-A_5412-02 RequestCard - Parameter CardType und DisplayText" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_03") echo "Executing test case "TIP1-A_5412-03 RequestCard - Parameter Cardtyp Fehler 4051" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_04") echo "Executing test case "TIP1-A_5412-04 RequestCard - Parameter TimeOut" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_05") echo "Executing test case "TIP1-A_5412-05 RequestCard - Parameter TimeOut Fehler 4202" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_06") echo "Executing test case "TIP1-A_5412-06 RequestCard - Default TimeOut Fehler 4202" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_07") echo "Executing test case "TIP1-A_5412-07 RequestCard - Nicht unterstuetzter Kartentyp Fehler 4058" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_08") echo "Executing test case "TIP1-A_5412-08 RequestCard - Syntaxfehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_01") echo "Executing test case "TIP1-A_5410-01 TUC_KON_057 – Gutfall  Default-DisplayMessage" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_02") echo "Executing test case "TIP1-A_5410-02 TUC_KON_057 - Parameter DisplayMsg und TimeOut" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_03") echo "Executing test case "TIP1-A_5410-03 TUC_KON_057 - Karte nicht entfernt Fehler 4203" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_04") echo "Executing test case "TIP1-A_5410-04 TUC_KON_057 - Ausfuehrung auf leerem Slot" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_05") echo "Executing test case "TIP1-A_5410-05 TUC_KON_057 - Display belegt Fehler 4039" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_06") echo "Executing test case "TIP1-A_5410-06 TUC_KON_057 - Zugriff auf KT Fehler 4044" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_07") echo "Executing test case "TIP1-A_5410-07 TUC_KON_057 - Ungueltige Slot-ID Fehler 4097" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_03") echo "Executing test case "TIP1-A_5409-03 TUC_KON_056 - Display belegt Fehler 4039" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_05") echo "Executing test case "TIP1-A_5409-05 TUC_KON_056 - KT nicht aktiv Fehler 4221" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_06") echo "Executing test case "TIP1-A_5409-06 TUC_KON_056 - Falscher Kartentyp Fehler 4051" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_07") echo "Executing test case "TIP1-A_5409-07 TUC_KON_056 - Ungültige Kartenslot-ID Fehler 4097" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_08") echo "Executing test case "TIP1-A_5409-08 TUC_KON_056 - KT nicht verbunden Fehler 4222" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5530_01") echo "Executing test case "TIP1-A_5530-01  - - NET_TI_OFFENE_FD - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5530_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5537_01") echo "Executing test case "TIP1-A_5537-01 IP-Routinginformationen \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5537_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5011_01") echo "Executing test case "TIP1-A_5011-01 Import von Kartenterminal-Informationen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5011_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4985_02") echo "Executing test case "TIP1-A_4985-02 TUC_KON_055 - CT.CONNECTED = Ja \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4985_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4557_01") echo "Executing test case "TIP1-A_4557-01 bekannt - zugewiesen - bekannt \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4557_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4557_02") echo "Executing test case "TIP1-A_4557-02 gepairt - aktiv - gepairt - zugewiesen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4557_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4556_01") echo "Executing test case "TIP1-A_4556-01 Erfolgreiches Pairing \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4556_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4556_02") echo "Executing test case "TIP1-A_4556-02 Kein Pairing für KTmit falscher Firmware \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4556_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4555_01") echo "Executing test case "TIP1-A_4555-01 Manuelles Hinzufuegen per IP-Adresse \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4555_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4555_02") echo "Executing test case "TIP1-A_4555-02 Manuelles Hinzufuegen mit allen Parametern \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4555_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4554_01") echo "Executing test case "TIP1-A_4554-01 Manuelles Bearbeiten eines KT-Eintrags \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4554_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4554_02") echo "Executing test case "TIP1-A_4554-02 Fehlerhaftes Bearbeiten eines KT-Eintrags \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4554_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4553_01") echo "Executing test case "TIP1-A_4553-01 Kartenterminaleintraege \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4553_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4552_01") echo "Executing test case "TIP1-A_4552-01 Manueller Verbindungsversuch zu Kartenterminals \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4552_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4551_01") echo "Executing test case "TIP1-A_4551-01 Einsichtnahme von Kartenterminaleintraegen \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4551_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_01") echo "Executing test case "TIP1-A_4550-01 Anzeige und Default-Werte \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_02") echo "Executing test case "TIP1-A_4550-02 Service Discovery Port und Cycle \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_07") echo "Executing test case "TIP1-A_4550-07 Wertebereiche \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_02") echo "Executing test case "TIP1-A_4545-02 TUC_KON_050 CORRELATION=gepairt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_05") echo "Executing test case "TIP1-A_4545-05 TUC_KON_050 CT.CONNECTED CT.ACTIVEROLE=admin" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_06") echo "Executing test case "TIP1-A_4545-06 TUC_KON_050 - Fehler 4028" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_08") echo "Executing test case "TIP1-A_4545-08 TUC_KON_050 - Fehler 4029 Falsches Shared Secret" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_02") echo "Executing test case "TIP1-A_4546-02 TUC_KON_054 - Service Announcement bei bekannter MAC-Adresse" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_03") echo "Executing test case "TIP1-A_4546-03 TUC_KON_054 - Manuelles Hinzufuegen bei neuer MAC-Adresse" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_05") echo "Executing test case "TIP1-A_4546-05 TUC_KON_054 - Fehler 4033" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_06") echo "Executing test case "TIP1-A_4546-06 TUC_KON_054 - Fehler 4035" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_07") echo "Executing test case "TIP1-A_4546-07 TUC_KON_054 - Fehler 4036" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_08") echo "Executing test case "TIP1-A_4546-08 TUC_KON_054 - Fehler 4034" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4547_04") echo "Executing test case "TIP1-A_4547-04 - TUC_KON_051 - Display kurz belegt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4547_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4547_05") echo "Executing test case "TIP1-A_4547-05 - TUC_KON_051 - Fehler 4039" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4547_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_01") echo "Executing test case "TIP1-A_4548-01 TUC_KON_053 - Erfolgreiches Pairing \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_02") echo "Executing test case "TIP1-A_4548-02 TUC_KON_053 - Fehler 4042 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4548_02_neu") echo "Executing test case "TIP1-A_4548-02_neu TUC_KON_053 - Fehler 4042 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_02_neu.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_03") echo "Executing test case "TIP1-A_4548-03 TUC_KON_053 - Fehler 4040 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_05") echo "Executing test case "TIP1-A_4548-05 TUC_KON_053 - EHEALTH TERMINAL AUTHENTICATE Fehler 4041 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4542_01") echo "Executing test case "TIP1-A_4542-01 Reaktion auf KT-Slot-Ereignis_Karte entfernt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4542_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4549_01") echo "Executing test case "TIP1-A_4549-01 Initialisierung Kartenterminaldienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4549_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4543_01") echo "Executing test case "TIP1-A_4543-01 KT-Statusanpassung bei Beginn eines Updatevorgangs \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4543_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4544_01") echo "Executing test case "TIP1-A_4544-01 KT-Statusanpassung bei Ende eines Updatevorgangs \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4544_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4544_02") echo "Executing test case "TIP1-A_4544-02 KT-Statusanpassung bei Ende eines Updatevorgangs - Nicht unterst. Vers. \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4544_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4536_02") echo "Executing test case "TIP1-A_4536-02 TLS-Verbindung zu Kartenterminals halten - KEEP ALIVE" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4536_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4537_01") echo "Executing test case "TIP1-A_4537-01 KT-Statusanpassung bei Beendigung o. Timeout einer Netzwerkverbindung - KT absch." ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4537_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4539_03") echo "Executing test case "TIP1-A_4539-03 Robuster Kartenterminaldienst - Anderes KT" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4539_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4540_01") echo "Executing test case "TIP1-A_4540-01 Reaktion auf KT-Service-Announcement bei deaktiviertem Service Discovery" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4540_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4540_02") echo "Executing test case "TIP1-A_4540-02 Reaktion auf KT-Service-Announcement bei aktiviertem Service Discovery" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4540_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4540_04") echo "Executing test case "TIP1-A_4540-04 Reaktion auf Dienstbeschreibungspakete bei Kartenterminal mit CT.CORRELATION  Bekannt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4540_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5413_02") echo "Executing test case "TIP1-A_5413-02 EjectCard – CardHandle  DisplayMsg und TimeOut" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5413_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5413_03") echo "Executing test case "TIP1-A_5413-03 EjectCard - Syntaxfehler 4000" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5413_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5413_04") echo "Executing test case "TIP1-A_5413-04 EjectCard - Karte nicht entfernt Fehler 4203" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5413_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5413_05") echo "Executing test case "TIP1-A_5413-05 EjectCard - Parameter TimeOut Fehler 4203" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5413_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_01") echo "Executing test case "TIP1-A_5412-01 RequestCard - Pflichtparameter" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5411_01") echo "Executing test case "TIP1-A_5411-01 Basisanwendung Kartenterminaldienst" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5411_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_08") echo "Executing test case "TIP1-A_5410-08 TUC_KON_057 - KT nicht aktiv Fehler 4221" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_09") echo "Executing test case "TIP1-A_5410-09 TUC_KON_057 - KT nicht verbunden Fehler 4222" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_01") echo "Executing test case "TIP1-A_5409-01 TUC_KON_056 Gutfall" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_02") echo "Executing test case "TIP1-A_5409-02 TUC_KON_056 - CardType und DisplayMsg" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5409_04") echo "Executing test case "TIP1-A_5409-04 TUC_KON_056 - Zugriff auf KT Fehler 4044" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5409_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4985_01") echo "Executing test case "TIP1-A_4985-01 TUC_KON_055 - CT.CONNECTED = Nein" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4985_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4985_03") echo "Executing test case "TIP1-A_4985-03 TUC_KON_055 - SICCT Fehler" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4985_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4985_05") echo "Executing test case "TIP1-A_4985-05 TUC_KON_055 - CT.VALID_VERSION" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4985_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4555_03") echo "Executing test case "TIP1-A_4555-03 Manuelles Hinzufuegen mit falschen Parametern \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4555_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_03") echo "Executing test case "TIP1-A_4550-03 Service Discovery TimeOut \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_04") echo "Executing test case "TIP1-A_4550-04 Keep Alive \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_05") echo "Executing test case "TIP1-A_4550-05 TLS Handshake \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4550_06") echo "Executing test case "TIP1-A_4550-06 Service Discovery deaktiviert \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4550_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_01") echo "Executing test case "TIP1-A_4545-01 TUC_KON_050 CORRELATION=aktiv" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_03") echo "Executing test case "TIP1-A_4545-03 TUC_KON_050 CORRELATION=zugewiesen" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_04") echo "Executing test case "TIP1-A_4545-04 TUC_KON_050 CORRELATION=bekannt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_07") echo "Executing test case "TIP1-A_4545-07 TUC_KON_050 - Fehler 4029 Falsches Zertifikat" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4545_09") echo "Executing test case "TIP1-A_4545-09 TUC_KON_050 - Fehler 4030 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4545_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_01") echo "Executing test case "TIP1-A_4546-01 TUC_KON_054 - Service-Announcement bei neuer MAC-Adresse" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_04") echo "Executing test case "TIP1-A_4546-04 TUC_KON_054 - Manuelles Hinzufuegen bei bekannter MAC-Adresse" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4547_01") echo "Executing test case "TIP1-A_4547-01 - TUC_KON_051" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4547_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4547_02") echo "Executing test case "TIP1-A_4547-02 - TUC_KON_051 - Mode = OutputWait" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4547_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4547_03") echo "Executing test case "TIP1-A_4547-03 - TUC_KON_051 - Mode = OutputErase" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4547_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_04") echo "Executing test case "TIP1-A_4548-04 TUC_KON_053 - SICCT INIT CT SESSION Fehler 4041 \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4548_06") echo "Executing test case "TIP1-A_4548-06 TUC_KON_053 - Fingerprint nicht bestätigt \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4548_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4986_01") echo "Executing test case "TIP1-A_4986-01 Informationsparameter des Kartenterminaldienstes \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4986_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4541_01") echo "Executing test case "TIP1-A_4541-01 Reaktion auf KT-Slot-Ereignis_Karte eingesteckt" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4541_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5408_01") echo "Executing test case "TIP1-A_5408-01 Terminal-Anzeigen beim Anfordern und Auswerfen von Karten" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5408_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5543_01") echo "Executing test case "TIP1-A_5543-01 Keine manuelle PIN-Eingabe fuer gSMC-K \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5543_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5541_01") echo "Executing test case "TIP1-A_5541-01 Testung noch nicht möglich" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5541_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4546_09") echo "Executing test case "TIP1-A_4546-09 TUC_KON_054 - Fehler 4037" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4546_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4554_03") echo "Executing test case "TIP1-A_4554-03 Fehlerhaftes Bearbeiten ADMIN_USERNAME" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4554_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4554_04") echo "Executing test case "TIP1-A_4554-04 Erfolgreiches Bearbeiten ADMIN_PASSWORD" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4554_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4557_03") echo "Executing test case "TIP1-A_4557-03 bekannt - zugewiesen scheitert bei bekanntem Hostname \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_4557_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5011_02") echo "Executing test case "TIP1-A_5011-02 Import bei neuer Konnektor-Identität \(interaktiv\)" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5011_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_10") echo "Executing test case "TIP1-A_5410-10 TUC_KON_057 - Ungueltige CtID Fehler 4096" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5410_11") echo "Executing test case "TIP1-A_5410-11 TUC_KON_057 - Karte fremdreserviert Fehler 4093" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5410_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5412_09") echo "Executing test case "TIP1-A_5412-09 RequestCard - ungültige CtId" ..."
		TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5412_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_02") echo "Executing test case "VSDM-A_2575-02  - - ReadVSD - Pruefungsnachweis \(Ergebnis = 2\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_01") echo "Executing test case "VSDM-A_2575-01  - - ReadVSD - Pruefungsnachweis \(Ergebnis = 1\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_03") echo "Executing test case "VSDM-A_2575-03  - - ReadVSD - Pruefungsnachweis \(Ergebnis = 3\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_04") echo "Executing test case "VSDM-A_2575-04 ReadVSD - Pruefungsnachweis \(Ergebnis = 4\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_05") echo "Executing test case "VSDM-A_2575-05 ReadVSD - Pruefungsnachweis \(Ergebnis = 5\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2575_06") echo "Executing test case "VSDM-A_2575-06 ReadVSD - Pruefungsnachweis \(Ergebnis = 6\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2575_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2576_01") echo "Executing test case "VSDM-A_2576-01  - - ReadVSD - Pruefungsnachweis von der eGK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2576_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2576_02") echo "Executing test case "VSDM-A_2576-02 Pruefungsnachweis von anderem Mandanten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2576_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2567_01") echo "Executing test case "VSDM-A_2567-01 ReadVSD – VD  PD und Status" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2567_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2568_01") echo "Executing test case "VSDM-A_2568-01 ReadVSD - gesperrte Gesundheitsanwendung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2568_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2569_01") echo "Executing test case "VSDM-A_2569-01 ReadVSD - AUT-Zertifikat der eGK offline ungültig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2569_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2570_01") echo "Executing test case "VSDM-A_2570-01 ReadVSD - AUT-Zertifikat der eGK online ungueltig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2570_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2571_01") echo "Executing test case "VSDM-A_2571-01 ReadVSD - technischer Fehler" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2571_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2572_01") echo "Executing test case "VSDM-A_2572-01 ReadVSD - GVD in Antwort enthalten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2572_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2573_01") echo "Executing test case "VSDM-A_2573-01 Echtheitspruefung eGK durch gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2573_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2573_02") echo "Executing test case "VSDM-A_2573-02 Echtheitsprüfung eGK durch Aktualisierung und einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2573_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2574_01") echo "Executing test case "VSDM-A_2574-01 Echtheitspruefung SM-B durch gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2574_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2574_02") echo "Executing test case "VSDM-A_2574-02 Echtheitsprüfung SM-B durch einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2574_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2574_03") echo "Executing test case "VSDM-A_2574-03 Echtheitspruefung HBA durch gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2574_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2574_04") echo "Executing test case "VSDM-A_2574-04 Echtheitsprüfung HBA durch einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2574_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2577_01") echo "Executing test case "VSDM-A_2577-01 ReadVSD - Pruefungsnachweis lesen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2577_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_01") echo "Executing test case "VSDM-A_2578-01 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 1\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_02") echo "Executing test case "VSDM-A_2578-02 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 2\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_03") echo "Executing test case "VSDM-A_2578-03 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 3\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_04") echo "Executing test case "VSDM-A_2578-04 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 4\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_05") echo "Executing test case "VSDM-A_2578-05 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 5\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2578_06") echo "Executing test case "VSDM-A_2578-06 ReadVSD - Pruefungsnachweis erzeugen \(Ergebnis 6\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2578_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_01") echo "Executing test case "VSDM-A_2579-01 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 1\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_02") echo "Executing test case "VSDM-A_2579-02 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 2\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_06") echo "Executing test case "VSDM-A_2579-06 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 6\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_05") echo "Executing test case "VSDM-A_2579-05 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 5\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_04") echo "Executing test case "VSDM-A_2579-04 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 4\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2579_03") echo "Executing test case "VSDM-A_2579-03 ReadVSD - Pruefungsnachweis schreiben \(Ergebnis 3\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2579_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2580_01") echo "Executing test case "VSDM-A_2580-01 ReadVSD - Aktualisierungsauftraege ermitteln - Keine Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2580_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2580_02") echo "Executing test case "VSDM-A_2580-02 ReadVSD - Aktualisierungsauftraege ermitteln - Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2580_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2581_01") echo "Executing test case "VSDM-A_2581-01 Fachmodul VSDM - ReadVSD - Aktualisierung durchfuehren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2581_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2582_01") echo "Executing test case "VSDM-A_2582-01 ReadVSD - Aktualisierungsauftraege ermitteln wegen gesperrter Gesundheitsanwendung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2582_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2582_02") echo "Executing test case "VSDM-A_2582-02 ReadVSD - Aktualisierungsauftraege ermitteln wegen gesper. Gesundheitsanwendung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2582_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2583_01") echo "Executing test case "VSDM-A_2583-01 ReadVSD - AUT-Zertifikat der eGK offline ungültig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2583_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2584_01") echo "Executing test case "VSDM-A_2584-01 ReadVSD - AUT-Zertifikat der eGK online ungueltig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2584_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2585_01") echo "Executing test case "VSDM-A_2585-01 Keine Versichertendaten nach Sperrung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2585_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2586_01") echo "Executing test case "VSDM-A_2586-01 ReadVSD - Protokollierung VSD-Aktualisierung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2586_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2587_01") echo "Executing test case "VSDM-A_2587-01 ReadVSD - Protokollierung GVD Lesen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2587_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2604_01") echo "Executing test case "VSDM-A_2604-01 Fehlermeldung wenn Gesundheitsanwendung im Ablauf gesperrt wird" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2604_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2605_01") echo "Executing test case "VSDM-A_2605-01 Keine Fehlermeldung wenn Gesundheitsanwendung entsperrt wird" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2605_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2652_01") echo "Executing test case "VSDM-A_2652-01 ReadVSD - Base64-Kodierung von Ausgangsdaten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2652_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2660_01") echo "Executing test case "VSDM-A_2660-01 Inkonsistenten VSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2660_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2662_01") echo "Executing test case "VSDM-A_2662-01 Abbruch der gegenseitigen C2C bei Aktualisierung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2662_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2772_01") echo "Executing test case "VSDM-A_2772-01 Pruefungsnachweis parallel zur SOAP-Response schreiben" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2772_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2784_01") echo "Executing test case "VSDM-A_2784-01 GVD nicht aus dem Container EF.VD lesen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2784_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2792_01") echo "Executing test case "VSDM-A_2792-01 ReadVSD im Dienstverzeichnisdienst" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2792_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2998_01") echo "Executing test case "VSDM-A_2998-01 Abbruch der Operation ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2998_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2998_02") echo "Executing test case "VSDM-A_2998-02 Abbruch der Operation ReadVSD \(Transaktionsflag = 1\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2998_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2775_01") echo "Executing test case "VSDM-A_2775-01 Aufrufkontext prüfen - ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2775_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2775_02") echo "Executing test case "VSDM-A_2775-02 Aufrufkontext prüfen - ReadKVK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2775_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2565_01") echo "Executing test case "VSDM-A_2565-01 Parallele Aufrufe von ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2565_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_02") echo "Executing test case "VSDM-A_2566-02 TIMEOUT_VSDM" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_03") echo "Executing test case "VSDM-A_2566-03 SRVNAME_INT_VSDM" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_04") echo "Executing test case "VSDM-A_2566-04 KEY_RECEIPT" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_05") echo "Executing test case "VSDM-A_2566-05 EGK_ALWAYS" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_06") echo "Executing test case "VSDM-A_2566-06 MAXTIME_VSDM" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_07") echo "Executing test case "VSDM-A_2566-07 TIMEOUT_TI_OFFLINE" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_08") echo "Executing test case "VSDM-A_2566-08 LOG_FM_PERF" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_09") echo "Executing test case "VSDM-A_2566-09 LOG_FM_xxx_DAYS \(LANGE LAUFZEIT\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2588_01") echo "Executing test case "VSDM-A_2588-01 ReadVSD - Pruefungsnachweis mit Prüfziffer von Fachdienst" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2588_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2588_02") echo "Executing test case "VSDM-A_2588-02 ReadVSD - Pruefungsnachweis mit Prüfziffer von UFS" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2588_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2588_03") echo "Executing test case "VSDM-A_2588-03 ReadVSD - Pruefungsnachweis mit Fehlercode \(UFS-Fehler\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2588_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_04") echo "Executing test case "VSDM-A_2589-04 ReadVSD - Fachdienst nicht erreichbar" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2590_01") echo "Executing test case "VSDM-A_2590-01 ReadVSD - Pruefungsnachweis komprimieren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2590_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2594_02") echo "Executing test case "VSDM-A_2594-02 Pruefungsnachweis nicht vorhanden" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2594_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2595_01") echo "Executing test case "VSDM-A_2595-01 Pruefungsnachweis nicht entschluesselbar" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2595_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2597_01") echo "Executing test case "VSDM-A_2597-01 GetUpdateFlags in ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2597_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2597_02") echo "Executing test case "VSDM-A_2597-02 GetUpdateFlags in AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2597_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2601_01") echo "Executing test case "VSDM-A_2601-01 PerformUpdates und GetNextCommandPackage bei ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2601_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2601_02") echo "Executing test case "VSDM-A_2601-02 PerformUpdates und GetNextCommandPackage bei AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2601_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2602_01") echo "Executing test case "VSDM-A_2602-01 Reihenfolge der Abarbeitung der Aktualisierungsauftraege" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2602_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2603_01") echo "Executing test case "VSDM-A_2603-01 Separate Aktualisierungen fuer mehrere UpdateIds" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2603_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_04") echo "Executing test case "VSDM-A_2612-04 Aussenverhalten von VSDM-UC_04 - Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_05") echo "Executing test case "VSDM-A_2612-05 Aussenverhalten von VSDM-UC_05" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_06") echo "Executing test case "VSDM-A_2612-06 Aussenverhalten von VSDM-UC_10" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_07") echo "Executing test case "VSDM-A_2612-07 Aussenverhalten von VSDM-UC_07" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_08") echo "Executing test case "VSDM-A_2612-08 Ergebnis am Kartenterminal anzeigen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2613_01") echo "Executing test case "VSDM-A_2613-01 Ausloesen von AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2613_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2613_02") echo "Executing test case "VSDM-A_2613-02 Kein Ausloesen von AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2613_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_01") echo "Executing test case "VSDM-A_2614-01 VSD-Aktualisierung erfolgreich durchgefuehrt" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_02") echo "Executing test case "VSDM-A_2614-02 Keine VSD-Aktualisierungsauftraege" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_04") echo "Executing test case "VSDM-A_2614-04 Fachdienst nicht erreichbar" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_05") echo "Executing test case "VSDM-A_2614-05 Aktualisierung nicht erfolgreich" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_06") echo "Executing test case "VSDM-A_2614-06 AUT-Zertifikat nach Onlinepruefung nicht gueltig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_07") echo "Executing test case "VSDM-A_2614-07 Onlinepruefung des AUT-Zertifikats nicht moeglich" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_08") echo "Executing test case "VSDM-A_2614-08 Maximaler Offline-Zeitraum ueberschritten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_01") echo "Executing test case "VSDM-A_2615-01 Pruefungsnachweis schreiben \(Ergebnis =2\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_02") echo "Executing test case "VSDM-A_2615-02 Pruefungsnachweis schreiben \(Ergebnis =1\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_01") echo "Executing test case "VSDM-A_2616-01 Textanzeige am Kartenterminal" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_02") echo "Executing test case "VSDM-A_2616-02 Löschen der Textanzeige am Kartenterminal nach definierter Zeit" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_03") echo "Executing test case "VSDM-A_2616-03 Löschen der Textanzeige am Kartenterminal nach Ziehen der eGK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2619_01") echo "Executing test case "VSDM-A_2619-01 Aktualisierungsauftraege ermitteln - Keine Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2619_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2619_02") echo "Executing test case "VSDM-A_2619-02 Aktualisierungsauftraege ermitteln - Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2619_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_04") echo "Executing test case "VSDM-A_2621-04 Echtheitspruefung eGK - gegenseitige C2C mit HBA" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2622_01") echo "Executing test case "VSDM-A_2622-01 Echtheitspruefung SMC-B - gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2622_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2622_02") echo "Executing test case "VSDM-A_2622-02 Echtheitspruefung SMC-B - einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2622_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2623_01") echo "Executing test case "VSDM-A_2623-01 AutoUpdateVSD - Protokollierung VSD-Aktualisierung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2623_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2624_01") echo "Executing test case "VSDM-A_2624-01 Fehlermeldung wenn Gesundheitsanwendung im Ablauf gesperrt wird" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2624_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2625_01") echo "Executing test case "VSDM-A_2625-01 Keine Fehlermeldung wenn Gesundheitsanwendung entsperrt wird" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2625_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2636_01") echo "Executing test case "VSDM-A_2636-01 Dokumentiertes Protokollformat \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2636_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2639_01") echo "Executing test case "VSDM-A_2639-01 Felder im Performance-Protokoll \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2639_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2642_01") echo "Executing test case "VSDM-A_2642-01 Erfasste Operationen im Performance-Protokoll \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2642_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2649_01") echo "Executing test case "VSDM-A_2649-01 Protokolldateien begrenzen auf 180 Tage \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2649_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2650_01") echo "Executing test case "VSDM-A_2650-01 Korrelierende Vorgangsnummern für zusammengehoerende Eintraege \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2650_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2650_02") echo "Executing test case "VSDM-A_2650-02 Korrelierende Vorgangsnummern - AutoUpdateVSD \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2650_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2651_01") echo "Executing test case "VSDM-A_2651-01 Felder im Fehlerprotokoll \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2651_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2653_01") echo "Executing test case "VSDM-A_2653-01 Pruefungsnachweis mit ErrorCode" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2653_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2653_02") echo "Executing test case "VSDM-A_2653-02 Pruefungsnachweis mit ErrorCode \(CCS-Fehler\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2653_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2655_01") echo "Executing test case "VSDM-A_2655-01 Pruefungsnachweis ueberschreiben" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2655_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2664_02") echo "Executing test case "VSDM-A_2664-02 Ereignisdienst - maximale Offlinezeit überschritten - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2664_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2665_01") echo "Executing test case "VSDM-A_2665-01 Fachmodul VSDM reagiert auf CARD-INSERTED" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2665_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2665_02") echo "Executing test case "VSDM-A_2665-02 NETWORK-VPN_TI-UP und NETWORK-VPN_TI-DOWN" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2665_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2667_01") echo "Executing test case "VSDM-A_2667-01 VSDM-PROGRESS-Ereignisse" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2667_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2668_01") echo "Executing test case "VSDM-A_2668-01 Fachmodul - Endpunkt-Adressen fuer Intermediaer bilden" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2668_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2668_02") echo "Executing test case "VSDM-A_2668-02 Fachmodul - Endpunkt-Adressen fuer Intermediaer bilden - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2668_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2687_01") echo "Executing test case "VSDM-A_2687-01 ReadVSD fuer eGK G1plus" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2687_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2687_02") echo "Executing test case "VSDM-A_2687-02 ReadVSD fuer eGK G2" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2687_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2708_01") echo "Executing test case "VSDM-A_2708-01 Werte fuer StatusVD in Antwortnachricht" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2708_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2745_01") echo "Executing test case "VSDM-A_2745-01 Mandantengebundene Schluesselerzeugung fuer Pruefungsnachweis \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2745_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2745_02") echo "Executing test case "VSDM-A_2745-02 Pruefungsnachweis mandantenspezifisch verschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2745_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2745_03") echo "Executing test case "VSDM-A_2745-03 Pruefungsnachweis mandantenspezifisch entschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2745_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2749_01") echo "Executing test case "VSDM-A_2749-01 SOAP Faults o. gematik-Fehlerstruktur m. Anfragenachricht u. Vorgangsnr. protokoll." ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2749_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2749_03") echo "Executing test case "VSDM-A_2749-03 gematik SOAP Fault mit Anfragenachricht und Vorgangsnummer protokollieren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2749_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2752_01") echo "Executing test case "VSDM-A_2752-01 Aktualisierungen einzeln durchfuehren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2752_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2770_01") echo "Executing test case "VSDM-A_2770-01 Pruefungsnachweis minimieren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2770_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2776_01") echo "Executing test case "VSDM-A_2776-01 VSDM_PNW-Key aus Eingabe ableiten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2776_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2777_01") echo "Executing test case "VSDM-A_2777-01 Mandantengebundene Schluesselerzeugung fuer Pruefungsnachweis \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2777_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2777_02") echo "Executing test case "VSDM-A_2777-02 Pruefungsnachweis mandantenspezifisch verschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2777_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2777_03") echo "Executing test case "VSDM-A_2777-03 Pruefungsnachweis mandantenspezifisch entschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2777_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2778_01") echo "Executing test case "VSDM-A_2778-01 Anzeige Masterschluessel \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2778_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2789_01") echo "Executing test case "VSDM-A_2789-01 Keine Protokollierung von Schluesselmaterial \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2789_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2979_01") echo "Executing test case "VSDM-A_2979-01 Unterstuetzte Versionen der VSDM Speicherstrukturen auf der eGK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2979_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2981_01") echo "Executing test case "VSDM-A_2981-01 Kartenterminal Fortschrittstexte bei ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2981_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2981_02") echo "Executing test case "VSDM-A_2981-02 Kartenterminal Fortschrittstexte bei AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2981_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2989_01") echo "Executing test case "VSDM-A_2989-01 Speicherstruktur des Containers EF.Pruefungsnachweises auf der eGK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2989_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3007_01") echo "Executing test case "VSDM-A_3007-01 Ermitteln der URL des zugeordneten VSDM Intermediaers" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_3007_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3020_01") echo "Executing test case "VSDM-A_3020-01 Konfiguration des Context zum Aufruf der Operation AutoUpdateVSD \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_3020_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2750_01") echo "Executing test case "VSDM-A_2750-01 Fachmodul VSDM - automatisches Loeschen innerhalb 30 Tagen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2750_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2563_01") echo "Executing test case "VSDM-A_2563-01 Abbruch nach Timeout UFS" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2563_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2563_02") echo "Executing test case "VSDM-A_2563-02 Abbruch nach Timeout CCS" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2563_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2565_02") echo "Executing test case "VSDM-A_2565-02 Parallele Aufrufe von ReadKVK" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2565_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2565_03") echo "Executing test case "VSDM-A_2565-03 Parallele Aufrufe von AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2565_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_01") echo "Executing test case "VSDM-A_2566-01 Existenz konfigurierbarer Parameter" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_06") echo "Executing test case "VSDM-A_2566-06 MAXTIME_VSDM" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_01") echo "Executing test case "VSDM-A_2589-01 ReadVSD - VSD-Aktualisierung erfolgreich durchgefuehrt" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_02") echo "Executing test case "VSDM-A_2589-02 ReadVSD - Keine VSD-Aktualisierungsauftraege" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_03") echo "Executing test case "VSDM-A_2589-03 ReadVSD - Keine Online-Verbindung vorhanden" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_05") echo "Executing test case "VSDM-A_2589-05 ReadVSD - Aktualisierung nicht erfolgreich" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_06") echo "Executing test case "VSDM-A_2589-06 AutoupdateVSD - AUT-Zertifikat nach Onlinepruefung nicht gueltig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_07") echo "Executing test case "VSDM-A_2589-07 ReadVSD - Onlinepruefung des AUT-Zertifikats nicht moeglich" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2589_08") echo "Executing test case "VSDM-A_2589-08 ReadVSD - Maximaler Offline-Zeitraum ueberschritten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2589_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2591_01") echo "Executing test case "VSDM-A_2591-01 ReadVSD - Pruefungsnachweis verschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2591_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2592_01") echo "Executing test case "VSDM-A_2592-01 Fachmodul VSDM - Pruefungsnachweis entschluesseln" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2592_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2594_01") echo "Executing test case "VSDM-A_2594-01 Pruefungsnachweis nicht entschluesselbar" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2594_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2606_01") echo "Executing test case "VSDM-A_2606-01 Abbruch aller weiteren Aktualisierungen bei Fehler in einer Aktualisierung" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2606_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2607_01") echo "Executing test case "VSDM-A_2607-01 ReadVSD für eGK der Generation 1" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2607_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2607_02") echo "Executing test case "VSDM-A_2607-02 AutoUpdateVSD für eGK der Generation 1" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2607_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_01") echo "Executing test case "VSDM-A_2612-01 Aussenverhalten von VSDM-UC_12" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_02") echo "Executing test case "VSDM-A_2612-02 Aussenverhalten von VSDM-UC_11" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2612_03") echo "Executing test case "VSDM-A_2612-03 Aussenverhalten von VSDM-UC_04 - Keine Aktualisierung vorrätig" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2612_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2614_03") echo "Executing test case "VSDM-A_2614-03 Keine Online-Verbindung vorhanden" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2614_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_03") echo "Executing test case "VSDM-A_2615-03 Pruefungsnachweis schreiben \(Ergebnis =3\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_04") echo "Executing test case "VSDM-A_2615-04 Pruefungsnachweis schreiben \(Ergebnis =4\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_05") echo "Executing test case "VSDM-A_2615-05 Pruefungsnachweis schreiben \(Ergebnis =5\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2615_06") echo "Executing test case "VSDM-A_2615-06 Pruefungsnachweis schreiben \(Ergebnis =6\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2615_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2620_01") echo "Executing test case "VSDM-A_2620-01 Aktualisierung durchfuehren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2620_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_01") echo "Executing test case "VSDM-A_2621-01 AutoUpdateVSD - Echtheitspruefung eGK - gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_02") echo "Executing test case "VSDM-A_2621-02 AutoUpdateVSD - Echtheitspruefung eGK - einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_03") echo "Executing test case "VSDM-A_2621-03 Echtheitspruefung eGK - gegenseitige C2C mit HBA" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2638_01") echo "Executing test case "VSDM-A_2638-01 Felder im Ablaufprotokoll \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2638_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2654_01") echo "Executing test case "VSDM-A_2654-01 Abbruch wenn Protokoll nicht auf eGK geschrieben" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2654_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2654_02") echo "Executing test case "VSDM-A_2654-02 Abbruch wenn Protokoll nicht auf eGK geschrieben - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2654_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2655_02") echo "Executing test case "VSDM-A_2655-02 Pruefungsnachweis ueberschreiben - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2655_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2664_01") echo "Executing test case "VSDM-A_2664-01 Ereignisdienst - maximale Offlinezeit überschritten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2664_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2667_02") echo "Executing test case "VSDM-A_2667-02 VSDM-PROGRESS-Ereignisse - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2667_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2687_03") echo "Executing test case "VSDM-A_2687-03 AutoUpdateVSD fuer eGK G1plus" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2687_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2687_04") echo "Executing test case "VSDM-A_2687-04 AutoUpdateVSD fuer eGK G2" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2687_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2749_02") echo "Executing test case "VSDM-A_2749-02 HTTP-Fehler mit Anfragenachricht und Vorgangsnummer protokollieren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2749_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2752_02") echo "Executing test case "VSDM-A_2752-02 Aktualisierung einzeln durchfuehren - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2752_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2779_01") echo "Executing test case "VSDM-A_2779-01 Masterschluessel zufaellig erzeugen \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2779_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2791_01") echo "Executing test case "VSDM-A_2791-01 Ausfuehrungszeiten im Performance-Protokoll \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2791_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2572_02") echo "Executing test case "VSDM-A_2572-02 Keine Berechtigung zum Lesen der GVD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2572_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2622_03") echo "Executing test case "VSDM-A_2622-03 Echtheitspruefung HBA - gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2622_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2622_04") echo "Executing test case "VSDM-A_2622-04 Echtheitspruefung HBA - einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2622_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2770_02") echo "Executing test case "VSDM-A_2770-02 Fachmodul VSDM - Pruefungsnachweis minimieren - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2770_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2989_02") echo "Executing test case "VSDM-A_2989-02 Speicherstruktur des Containers EF.Pruefungsnachweises auf der eGK - ReadVsd" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2989_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2573_03") echo "Executing test case "VSDM-A_2573-03 Fehler bei Echtheitsprüfung eGK durch gegenseitige C2C - Fehler 4056" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2573_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2573_04") echo "Executing test case "VSDM-A_2573-04 Fehler bei Echtheitsprüfung eGK durch Aktualisierung und einseitige C2C - Fehler 4057" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2573_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2587_02") echo "Executing test case "VSDM-A_2587-02 ReadVSD - Protokollierung GVD lesen nach Update" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2587_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2587_03") echo "Executing test case "VSDM-A_2587-03 ReadVSD - Keine Protokollierung  wenn GVD nicht gelesen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2587_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2588_04") echo "Executing test case "VSDM-A_2588-04 ReadVSD - Pruefungsnachweis mit Fehlercode \(CCS-Fehler\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2588_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_04") echo "Executing test case "VSDM-A_2616-04 Ergebnistext -Fehlende SMC-B-HBA-" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_05") echo "Executing test case "VSDM-A_2616-05 Ergebnistext -Fehler SM-B-HBA-" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_06") echo "Executing test case "VSDM-A_2616-06 Ergebnistext -Daten inkonsistent-" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_07") echo "Executing test case "VSDM-A_2616-07 Ergebnistext -Fehler-" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2616_08") echo "Executing test case "VSDM-A_2616-08 Weitere Ergebnistexte" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2616_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_05") echo "Executing test case "VSDM-A_2621-05 AutoUpdateVSD - Fehler Echtheitspruefung eGK - gegenseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2621_06") echo "Executing test case "VSDM-A_2621-06 AutoUpdateVSD - Fehler Echtheitspruefung eGK - einseitige C2C" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2621_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2566_10") echo "Executing test case "VSDM-A_2566-10 Default-Werte \(interaktiv\)" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2566_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2668_03") echo "Executing test case "VSDM-A_2668-03 Fachmodul Endpunkt-Adressen für Intermediär bilden - CMS" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_01_Spezifikation_Fachmodul_VSDM/VSDM_A_2668_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2609_01") echo "Executing test case "VSDM-A_2609-01 ReadKVK - Versichertendaten" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_02_ReadKVK/VSDM_A_2609_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2611_01") echo "Executing test case "VSDM-A_2611-01 KVK mit fehlerhafter Prüfsumme" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_02_ReadKVK/VSDM_A_2611_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	"VSDM_A_2611_02") echo "Executing test case "VSDM-A_2611-02 KVK mit fehlerhafter Prüfsumme" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_02_ReadKVK/VSDM_A_2611_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2626_01") echo "Executing test case "VSDM-A_2626-01 ReadKVK - Ablauf des Gueltigkeitsdatums" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_02_ReadKVK/VSDM_A_2626_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2793_01") echo "Executing test case "VSDM-A_2793-01 ReadKVK im Dienstverzeichnisdienst" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_02_ReadKVK/VSDM_A_2793_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2973_01") echo "Executing test case "VSDM-A_2973-01 Speicherstruktur von EF.PD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_03_Speicherstrukturen_eGK_fuer_VSDM/VSDM_A_2973_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2974_01") echo "Executing test case "VSDM-A_2974-01 Speicherstruktur von EF.VD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_03_Speicherstrukturen_eGK_fuer_VSDM/VSDM_A_2974_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2975_01") echo "Executing test case "VSDM-A_2975-01 Speicherstruktur von EF.GVD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_03_Speicherstrukturen_eGK_fuer_VSDM/VSDM_A_2975_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2976_01") echo "Executing test case "VSDM-A_2976-01 Speicherstruktur von EF.StatusVD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_03_Speicherstrukturen_eGK_fuer_VSDM/VSDM_A_2976_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2282_01") echo "Executing test case "VSDM-A_2282-01 Fachmodul VSDM - RequestHeader bei Aufruf GetUpdateFlags" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2282_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2282_02") echo "Executing test case "VSDM-A_2282-02 Fachmodul VSDM - RequestHeader bei Aufruf GetUpdateFlags" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2282_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2285_01") echo "Executing test case "VSDM-A_2285-01 Fachmodul VSDM - optionale Updates nicht ausfuehren" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2285_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2285_02") echo "Executing test case "VSDM-A_2285-02 Fachmodul VSDM - optionale Updates nicht ausfuehren - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2285_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2298_01") echo "Executing test case "VSDM-A_2298-01 Fachmodul VSDM - Sessioninformation fuer GetNextCommandPackage uebernehmen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2298_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2298_02") echo "Executing test case "VSDM-A_2298-02 Fachmodul VSDM -Sessioninformation fuer GetNextCommandPackage uebernehmen-AutoUpdVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2298_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2303_01") echo "Executing test case "VSDM-A_2303-01 Fachmodul VSDM - Request-Header bei Aufruf PerformUpdates" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2303_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2303_02") echo "Executing test case "VSDM-A_2303-02 Fachmodul VSDM - Request-Header bei Aufruf PerformUpdates - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2303_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2308_01") echo "Executing test case "VSDM-A_2308-01 Fachmodul VSDM - Operation PerformUpdates aufrufen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2308_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2308_02") echo "Executing test case "VSDM-A_2308-02 Fachmodul VSDM - Operation PerformUpdates aufrufen - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2308_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2310_01") echo "Executing test case "VSDM-A_2310-01 Fachmodul VSDM - Operation GetUdateFlags aufrufen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2310_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2310_02") echo "Executing test case "VSDM-A_2310-02 Fachmodul VSDM - Operation GetUdateFlags aufrufen - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2310_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2311_01") echo "Executing test case "VSDM-A_2311-01 Fachmodul VSDM - Operation GetNextCommandPackage aufrufen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2311_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2311_02") echo "Executing test case "VSDM-A_2311-02 Fachmodul VSDM - Operation GetNextCommandPackage aufrufen - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2311_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2318_01") echo "Executing test case "VSDM-A_2318-01 Fachmodul VSDM - Kommando-APDUs unveraendert durchreichen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2318_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2318_02") echo "Executing test case "VSDM-A_2318-02 Fachmodul VSDM - Kommando-APDUs unveraendert durchreichen - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2318_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2321_01") echo "Executing test case "VSDM-A_2321-01 Fachmodul VSDM - Request-Header bei Aufruf GetNextCommandPackage" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2321_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2321_02") echo "Executing test case "VSDM-A_2321-02 Fachmodul VSDM - Request-Header bei Aufruf GetNextCommandPackage - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2321_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2335_01") echo "Executing test case "VSDM-A_2335-01 Fachmodul VSDM - AdditionalInfo nicht nutzen" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2335_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2335_02") echo "Executing test case "VSDM-A_2335-02 Fachmodul VSDM - AdditionalInfo nicht nutzen - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2335_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2552_01") echo "Executing test case "VSDM-A_2552-01 Fachmodul VSDM - Abbruch bei unerwarteten Status-Code" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2552_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2552_02") echo "Executing test case "VSDM-A_2552-02 Fachmodul VSDM - Abbruch bei unerwarteten Status-Code - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2552_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2553_01") echo "Executing test case "VSDM-A_2553-01 Fachmodul VSDM - Response bei unerwarteten Status-Code" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2553_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2553_02") echo "Executing test case "VSDM-A_2553-02 Fachmodul VSDM - Response bei unerwarteten Status-Code - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2553_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3303_01") echo "Executing test case "VSDM-A_3303-01 Fachmodul VSDM - kein Pruefungsnachweis wenn Online nicht aktiviert" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3303_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_3008_01") echo "Executing test case "VSDM-A_3008-01 Abort ohne Kartenkommandos" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3008_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3008_02") echo "Executing test case "VSDM-A_3008-02 Abort bei unerwarteten Status-Code - ReadVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3008_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3008_03") echo "Executing test case "VSDM-A_3008-03 Abort ohne Kartenkommandos - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3008_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3008_04") echo "Executing test case "VSDM-A_3008-04 Abort bei unerwarteten Status-Code - AutoUpdateVSD" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3008_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2552_03") echo "Executing test case "VSDM-A_2552-03 Kein Abbruch bei `63 Cx`" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_2552_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4806_01") echo "Executing test case "TIP1-A_4806-01 Existenz einer LAN-seitigen Managementschnittstelle \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4806_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4806_02") echo "Executing test case "TIP1-A_4806-02 Weitere Testfallspezifikation noch nicht möglich" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4806_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_01") echo "Executing test case "TIP1-A_4810-01 Existenz der Benutzerverwaltung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_02") echo "Executing test case "TIP1-A_4810-02 Administrator-Rollen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_03") echo "Executing test case "TIP1-A_4810-03 Lokaler Administrator - Zugriff \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_04") echo "Executing test case "TIP1-A_4810-04 Lokaler Administrator - Konfigurationsdaten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_05") echo "Executing test case "TIP1-A_4810-05 Lokaler Administrator - keine Benutzerverwaltung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_06") echo "Executing test case "TIP1-A_4810-06 Remote Administrator - Zugriff \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_07") echo "Executing test case "TIP1-A_4810-07 Remote Administrator - Konfigurationsdaten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_08") echo "Executing test case "TIP1-A_4810-08 Remote Administrator - keine Benutzerverwaltung  kein Werksreset \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_09") echo "Executing test case "TIP1-A_4810-09 Super Administrator - Zugriff \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_10") echo "Executing test case "TIP1-A_4810-10 Super Administrator - Konfigurationsdaten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_12") echo "Executing test case "TIP1-A_4810-12 Super Administrator - Benutzerverwaltung MGM_ADMIN_RIGHTS \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_13") echo "Executing test case "TIP1-A_4810-13 eigene Kontaktdaten ändern \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_14") echo "Executing test case "TIP1-A_4810-14 eigenen Nutzernamen ändern \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4811_01") echo "Executing test case "TIP1-A_4811-01 Festlegung des Konnektornamens \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4811_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4812_01") echo "Executing test case "TIP1-A_4812-01 Anzeige der Versionsinformationen \(Selbstauskunft\) \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4812_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4813_01") echo "Executing test case "TIP1-A_4813-01 Persistieren der Konfigurationsdaten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4813_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4814_01") echo "Executing test case "TIP1-A_4814-01 Export- Import von Konfigurationsdaten" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4814_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4814_02") echo "Executing test case "TIP1-A_4814-02 Import Konfigurationsdaten bei höherer Firmwareversion" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4814_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4818_01") echo "Executing test case "TIP1-A_4818-01 Konfigurieren von Fachmodulen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4818_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4818_02") echo "Executing test case "TIP1-A_4818-02 Persistieren der Fachmodul-Konfigurationsdaten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4818_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4818_03") echo "Executing test case "TIP1-A_4818-03 Export- Import der Fachmodul-Konfiguration \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4818_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4819_01") echo "Executing test case "TIP1-A_4819-01 Konnektorneustart \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4819_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4820_01") echo "Executing test case "TIP1-A_4820-01 Werksreset \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4820_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4820_02") echo "Executing test case "TIP1-A_4820-02 alternativer Werksreset \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4820_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4821_01") echo "Executing test case "TIP1-A_4821-01 Leistungsumfang Online \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4821_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4821_02") echo "Executing test case "TIP1-A_4821-02 Leistungsumfang Signaturanwendungskomponente \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4821_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4821_03") echo "Executing test case "TIP1-A_4821-03 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4821_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4822_01") echo "Executing test case "TIP1-A_4822-01 Konfiguration Standalone-Betrieb \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4822_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4822_02") echo "Executing test case "TIP1-A_4822-02 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4822_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4823_01") echo "Executing test case "TIP1-A_4823-01 Konfiguration logische Trennung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4823_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4823_02") echo "Executing test case "TIP1-A_4823-02 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4823_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4824_01") echo "Executing test case "TIP1-A_4824-01 Freischaltdaten des Konnektors bearbeiten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4824_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4825_01") echo "Executing test case "TIP1-A_4825-01 Freischalten des Konnektors \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4825_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4826_01") echo "Executing test case "TIP1-A_4826-01 Status Konnektorfreischaltung einsehen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4826_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4831_01") echo "Executing test case "TIP1-A_4831-01 KT-Update nach Wiedererreichbarkeit neu anstossen" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4831_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4832_01") echo "Executing test case "TIP1-A_4832-01 TUC_KON_280 Gutfall und Fortschrittsanzeige" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4832_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4832_02") echo "Executing test case "TIP1-A_4832-02 TUC_KON_280 Integritaet UpdateInformation" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4832_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4832_03") echo "Executing test case "TIP1-A_4832-03 TUC_KON_280 Integritaet Firmware" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4832_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4832_04") echo "Executing test case "TIP1-A_4832-04 TUC_KON_280 Fehler bei Download" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4832_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4832_05") echo "Executing test case "TIP1-A_4832-05 TUC_KON_280 Interne Aktualisierung schlägt fehl" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4832_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4833_02") echo "Executing test case "TIP1-A_4833-02 Fehler - Download nicht moeglich \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4833_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4833_03") echo "Executing test case "TIP1-A_4833-03 Fehler - KT-Update fehlgeschlagen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4833_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4833_04") echo "Executing test case "TIP1-A_4833-04 Kartenterminalaktualisierung fuer 5 KTs und paralleles Arbeiten \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4833_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4834_01") echo "Executing test case "TIP1-A_4834-01 TUC_KON_282 -Manuelles Beziehen von UpdateInformationen" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4834_02") echo "Executing test case "TIP1-A_4834-02 TUC_KON_282 - Automatisiertes Beziehen von UpdateInformationen" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4834_03") echo "Executing test case "TIP1-A_4834-03 TUC_KON_282 - Konfigurationsdienst nicht erreichbar" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4834_04") echo "Executing test case "TIP1-A_4834-04 TUC_KON_282 - Serverzertifikat nicht korrekt" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
		"TIP1_A_4834_04") echo "Executing test case "TIP1-A_4834-04 TUC_KON_282 - Serverzertifikat nicht korrekt" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4834_05") echo "Executing test case "TIP1-A_4834-05 TUC_KON_282 - Fehler beim Beziehen der Updatelisten" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
		"TIP1_A_4834_06") echo "Executing test case "TIP1-A_4834-06 TUC_KON_282 - EC_Connector_Software_Out_Of_Date" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4834_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4834_07") echo "Executing test case "TIP1-A_4834-07 TUC_KON_282 - EC_CardTerminal_Software_Out_Of_Date" ..."
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4834_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4835_01") echo "Executing test case "TIP1-A_4835-01 Konfigurationswerte des KSR-Client - Super-Admin \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4835_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4835_02") echo "Executing test case "TIP1-A_4835-02 Konfigurationswerte des KSR-Client - Lokaler-Admin \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4835_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4835_03") echo "Executing test case "TIP1-A_4835-03 Konfigurationswerte des KSR-Client - Remote-Admin \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4835_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4835_04") echo "Executing test case "TIP1-A_4835-04 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4835_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4835_05") echo "Executing test case "TIP1-A_4835-05 Erprobungs-Update-Pakete \(interaktiv\)" ..."
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4835_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4836_01") echo "Executing test case "TIP1-A_4836-01 TUC_KON_282 - Automatische Pruefung und Download \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4836_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4837_01") echo "Executing test case "TIP1-A_4837-01 Uebersichtsseite des KSR-Client \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4837_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4837_02") echo "Executing test case "TIP1-A_4837-02 Uebersichtseite des KSR-Client - nicht gepairtes KT \(interaktiv\)" ..."
		TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4837_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4838_01") echo "Executing test case "TIP1-A_4838-01 Einsichtnahme in Update-Informationen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4838_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4839_02") echo "Executing test case "TIP1-A_4839-02 Lokales Einspielen von Updates \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4839_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4842_01") echo "Executing test case "TIP1-A_4842-01 Gehaeuseversiegelung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4842_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4843_01") echo "Executing test case "TIP1-A_4843-01 Zustandsanzeige \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4843_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_01") echo "Executing test case "TIP1-A_5005-01 MGM_LU_SAK und Protokollierung von Benutzernamen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5153_01") echo "Executing test case "TIP1-A_5153-01 TUC_Kon_283 -Infrastruktur Konfiguration aktualisieren-" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5153_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5153_02") echo "Executing test case "TIP1-A_5153-02 TUC_Kon_283 -Infrastruktur Konfiguration aktualisieren- Fehlerfall" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5153_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5542_01") echo "Executing test case "TIP1-A_5542-01 Konnektor Funktion zur Pruefung der Erreichbarkeit von Systemen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5542_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5650_01") echo "Executing test case "TIP1-A_5650-01 Remote Management Konnektor - Aufbau der Verbindung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5650_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5650_02") echo "Executing test case "TIP1-A_5650-02 Weitere Testfallspezifikation noch nicht möglich" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5650_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5651_01") echo "Executing test case "TIP1-A_5651-01 Remote Management Konnektor - Absicherung der Verbindung" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5651_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5651_02") echo "Executing test case "TIP1-A_5651-02 Ungültiges Zertifikat" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5651_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5652_01") echo "Executing test case "TIP1-A_5652-01 Remote Management Konnektor - Konfiguration Remote Management \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5652_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5652_02") echo "Executing test case "TIP1-A_5652-02 Remote Management Konnektor - Konfiguration ohne Rechte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5652_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5652_03") echo "Executing test case "TIP1-A_5652-03 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5652_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5653_01") echo "Executing test case "TIP1-A_5653-01 Remote Management Konnektor - Protokollierung Remote Management" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5653_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5655_01") echo "Executing test case "TIP1-A_5655-01 Deregistrierung bei Ausserbetriebnahme \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5655_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5657_01") echo "Executing test case "TIP1-A_5657-01 Freischaltung von Softwareupdates \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5657_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5657_02") echo "Executing test case "TIP1-A_5657-02 KT-Update via Remote Management" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5657_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5657_03") echo "Executing test case "TIP1-A_5657-03 Konnektor-Update via Remote Management" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5657_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_01") echo "Executing test case "TIP1-A_5658-01 Remote-Anmeldung als Super-Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_02") echo "Executing test case "TIP1-A_5658-02 Remote-Anmeldung als lokaler Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_03") echo "Executing test case "TIP1-A_5658-03 Anmeldung an Managementschnittstelle als Remote Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_04") echo "Executing test case "TIP1-A_5658-04 Anmeldung an Managementschnittstelle als lokaler Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_05") echo "Executing test case "TIP1-A_5658-05 Anmeldung an Managementschnittstelle als Super-Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5658_06") echo "Executing test case "TIP1-A_5658-06 Remote-Anmeldung als Remote Administrator \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5658_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5659_01") echo "Executing test case "TIP1-A_5659-01 Bewusste Entscheidung bei Freischaltung von Softwareupdates \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5659_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5938_01") echo "Executing test case "TIP1-A_5938-01 TUC_KON_284 -KSR-Client initialisieren-" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5938_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4807_01") echo "Executing test case "TIP1-A_4807-01 Mandantenuebergreifende Managementschnttstelle \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4807_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4810_11") echo "Executing test case "TIP1-A_4810-11 Super Administrator - Benutzerverwaltung MGM_USER_LIST \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4810_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4827_01") echo "Executing test case "TIP1-A_4827-01 Konnektorfreischaltung zuruecknehmen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4827_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4833_01") echo "Executing test case "TIP1-A_4833-01 Kartenterminalaktualisierung anstossen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4833_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4839_01") echo "Executing test case "TIP1-A_4839-01 Festlegung der durchzufuehrenden Updates \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4839_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4840_01") echo "Executing test case "TIP1-A_4840-01 Auslösen der durchzufuehrenden Updates \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4840_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4844_01") echo "Executing test case "TIP1-A_4844-01 Ethernet-Schnittstellen \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4844_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4840_02") echo "Executing test case "TIP1-A_4840-02 Auslösen eines Konnektor-Update mit gesetztem Zeitpunkt \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4840_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4843_02") echo "Executing test case "TIP1-A_4843-02 Zustandsanzeige Highspeed-Konnektor \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4843_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_02") echo "Executing test case "TIP1-A_5005-02 ANCL_TLS_MANDATORY \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_03") echo "Executing test case "TIP1-A_5005-03 ANCL_CAUT_MANDATORY" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5153_03") echo "Executing test case "TIP1-A_5153-03 TUC_Kon_283 -Fehler bei Download" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5153_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5153_04") echo "Executing test case "TIP1-A_5153-04 TUC_Kon_283 - Fehler bei Aktualisieren der Gesamtnetzliste" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5153_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5153_05") echo "Executing test case "TIP1-A_5153-05 TUC_Kon_283 - Fehler bei Aktualisieren Konfigurationsinformationen" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5153_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5651_03") echo "Executing test case "TIP1-A_5651-03 Anfrage ohne TLS" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5651_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5651_04") echo "Executing test case "TIP1-A_5651-04 Remote Management Konnektor - Absicherung der Verbindung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5651_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_04") echo "Executing test case "TIP1-A_5005-04 ANCL_CAUT_MODE und ANCL_CUP_LIST" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_05") echo "Executing test case "TIP1-A_5005-05 ANCL_CCERT_LIST" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_06") echo "Executing test case "TIP1-A_5005-06 ANCL_DVD_OPEN" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_07") echo "Executing test case "TIP1-A_5005-07 Mandant \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_08") echo "Executing test case "TIP1-A_5005-08 Clientsystem und CS-AuthMerkmal \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_09") echo "Executing test case "TIP1-A_5005-09 Arbeitsplatz  Kartenterminal  CS_AP  Remote-PIN-KT \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_10") echo "Executing test case "TIP1-A_5005-10 SM-B_Verwaltet \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_11") echo "Executing test case "TIP1-A_5005-11 Kartenterminaldienst \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_12") echo "Executing test case "TIP1-A_5005-12 CT.HOSTNAME  CT_IP.ADDRESS  CT.TCP_PORT  CT.MAC_ADDRESS \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_13") echo "Executing test case "TIP1-A_5005-13 CT.CORRELATION \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_14") echo "Executing test case "TIP1-A_5005-14 CT.ADMIN_USERNAME und CT.ADMIN_PASSWORD \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_15") echo "Executing test case "TIP1-A_5005-15 CARD_TIMEOUT_CARD \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_16") echo "Executing test case "TIP1-A_5005-16 EVT_MAX_TRY" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_17") echo "Executing test case "TIP1-A_5005-17 EVT_MONITOR_OPERATIONS \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_17.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_18") echo "Executing test case "TIP1-A_5005-18 Zertifikatsdienst \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_18.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_19") echo "Executing test case "TIP1-A_5005-19 TSL manuell importieren \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_19.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_20") echo "Executing test case "TIP1-A_5005-20 CRL manuell importieren \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_20.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_21") echo "Executing test case "TIP1-A_5005-21 LOG_LEVEL_SYSLOG \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_21.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_22") echo "Executing test case "TIP1-A_5005-22 LOG_DAYS und FM_VSDM_LOG_DAYS \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_22.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_23") echo "Executing test case "TIP1-A_5005-23 LOG_SUCCESSFUL_CRYPTO_OPS" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_23.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_24") echo "Executing test case "TIP1-A_5005-24 ANLW_LAN-Parameter \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_24.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_25") echo "Executing test case "TIP1-A_5005-25 ANLW_WAN-Parameter \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_25.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_26") echo "Executing test case "TIP1-A_5005-26 ANLW_INTERNET_MODUS" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_26.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_27") echo "Executing test case "TIP1-A_5005-27 ANLW_INTRANET_ROUTES_MODUS" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_27.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_28") echo "Executing test case "TIP1-A_5005-28 ANLW_WAN_ADAPTER_MODUS" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_28.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_29") echo "Executing test case "TIP1-A_5005-29 ANLW_LEKTR_INTRANET_ROUTES" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_29.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_30") echo "Executing test case "TIP1-A_5005-30 ALNLW_AKTIVE_BESTANDSNETZE" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_30.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_31") echo "Executing test case "TIP1-A_5005-31 ANLW_SERVICE_TIMEOUT" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_31.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_32") echo "Executing test case "TIP1-A_5005-32 MGM_KONN_HOSTNAME \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_32.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_33") echo "Executing test case "TIP1-A_5005-33 DHCP-Server Basiskonfiguration \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_33.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_34") echo "Executing test case "TIP1-A_5005-34 DHCP-Server-Client-Gruppen" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_34.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_35") echo "Executing test case "TIP1-A_5005-35 DHCP-Server Client-Group-Konfiguration" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_35.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_36") echo "Executing test case "TIP1-A_5005-36 DHCP_CLIENT_LAN_STATE" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_36.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_37") echo "Executing test case "TIP1-A_5005-37 DHCP_CLIENT_WAN_STATE" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_37.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_38") echo "Executing test case "TIP1-A_5005-38 VPN-Client" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_38.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_39") echo "Executing test case "TIP1-A_5005-39 NTP_TIMEZONE und NTP_TIME \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_39.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_40") echo "Executing test case "TIP1-A_5005-40 DNS_SERVERS_INT \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_40.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_41") echo "Executing test case "TIP1-A_5005-41 DNS_SERVERS_LEKTR \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_41.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_42") echo "Executing test case "TIP1-A_5005-42 DNS_DOMAIN_VPN_ZUGD_INT \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_42.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_43") echo "Executing test case "TIP1-A_5005-43 DNS_DOMAIN_LEKTR \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_43.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_442") echo "Executing test case "TIP1-A_5005-442 DNS_ROOT_ANCHOR_URL \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_442.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_441") echo "Executing test case "TIP1-A_5005-441 Benutzerverwaltung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_441.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_45") echo "Executing test case "TIP1-A_5005-45 MGM_LU_ONLINE \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_45.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_46") echo "Executing test case "TIP1-A_5005-46 MGM_STANDALONE_KON \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_46.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_47") echo "Executing test case "TIP1-A_5005-47 MGM_LOGICAL_SEPARATION \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_47.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_48") echo "Executing test case "TIP1-A_5005-48 MGM_ZGDP_CONTRACTID und MGM_ZGDP_SMCB \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_48.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_49") echo "Executing test case "TIP1-A_5005-49 MGM_KSR_AUTOCHECK MGM_KSR_AUTODOWNLOAD und MGM_REMOTE_ALLOWED" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_49.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5005_51") echo "Executing test case "TIP1-A_5005-51 Context zum Aufruf der Operation AutoUpdateVSD \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5005_51.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_01") echo "Executing test case "VSDM-A_2596-01 Aussenverhalten von VSDM-UC_12" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_02") echo "Executing test case "VSDM-A_2596-02 Aussenverhalten von VSDM-UC_11" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_03") echo "Executing test case "VSDM-A_2596-03 Aussenverhalten von VSDM-UC_04 - Keine Aktualisierung vorrätig" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_04") echo "Executing test case "VSDM-A_2596-04 Aussenverhalten von VSDM-UC_04 - Aktualisierung vorrätig" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_05") echo "Executing test case "VSDM-A_2596-05 Aussenverhalten von VSDM-UC_05" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_06") echo "Executing test case "VSDM-A_2596-06 Aussenverhalten von -VSD-Status-Container lesen-" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_07") echo "Executing test case "VSDM-A_2596-07 Aussenverhalten von -PD und VD von der eGK lesen-" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_08") echo "Executing test case "VSDM-A_2596-08 Aussenverhalten von -GVD von der eGK lesen-" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_09") echo "Executing test case "VSDM-A_2596-09 Aussenverhalten von VSDM-UC_08" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_10") echo "Executing test case "VSDM-A_2596-10 Aussenverhalten von VSDM-UC_10" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2596_11") echo "Executing test case "VSDM-A_2596-11 Aussenverhalten von VSDM-UC_07" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2596_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2631_01") echo "Executing test case "VSDM-A_2631-01 ReadVSD - ErrorCode im Pruefungsnachweis" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2631_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2633_01") echo "Executing test case "VSDM-A_2633-01 ReadVSD gegen WSDL prüfen" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2633_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2634_01") echo "Executing test case "VSDM-A_2634-01 ReadVSD Ausgangsparameter" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2634_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2647_01") echo "Executing test case "VSDM-A_2647-01 ReadVSD - GVD in Antwort" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2647_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2647_02") echo "Executing test case "VSDM-A_2647-02 ReadVSD - GVD nicht in Antwort" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2647_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2658_01") echo "Executing test case "VSDM-A_2658-01  - - Konformität von VSDService zu BasicProfile 1.2" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2658_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2658_02") echo "Executing test case "VSDM-A_2658-02  - - Konformität von KVKService zu BasicProfile 1.2" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2658_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2675_01") echo "Executing test case "VSDM-A_2675-01  - - Erkennung invalider Request bei ReadVSD" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2675_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2675_02") echo "Executing test case "VSDM-A_2675-02  - - Erkennung invalider Request bei ReadKVK" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2675_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2676_01") echo "Executing test case "VSDM-A_2676-01  - - Zusaetzliches Header-Element bei ReadVSD" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2676_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2676_02") echo "Executing test case "VSDM-A_2676-02  - - Zusaetzliches Header-Element bei ReadKVK" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2676_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_01") echo "Executing test case "VSDM-A_2678-01  - - ReadVSD bei TLS-Server ohne Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_02") echo "Executing test case "VSDM-A_2678-02  - - ReadKVK bei TLS-Server ohne Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_03") echo "Executing test case "VSDM-A_2678-03  - - ReadVSD bei TLS-Server und TLS-Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_04") echo "Executing test case "VSDM-A_2678-04  - - ReadKVK bei TLS-Server und TLS-Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_05") echo "Executing test case "VSDM-A_2678-05  - - ReadVSD bei TLS-Server und Basic-Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_06") echo "Executing test case "VSDM-A_2678-06  - - ReadKVK bei TLS-Server und Basic-Client Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_07") echo "Executing test case "VSDM-A_2678-07  - - ReadVSD ohne Authentifizierung Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_08") echo "Executing test case "VSDM-A_2678-08  - - ReadKVK ohne Authentifizierung Gutfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_09") echo "Executing test case "VSDM-A_2678-09  - - ReadVSD bei TLS-Server ohne Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_10") echo "Executing test case "VSDM-A_2678-10  - - ReadKVK bei TLS-Server ohne Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_11") echo "Executing test case "VSDM-A_2678-11  - - ReadVSD bei TLS-Server und TLS-Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_12") echo "Executing test case "VSDM-A_2678-12  - - ReadKVK bei TLS-Server und TLS-Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_13") echo "Executing test case "VSDM-A_2678-13  - - ReadVSD bei TLS-Server und Basic-Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_14") echo "Executing test case "VSDM-A_2678-14  - - ReadKVK bei TLS-Server und Basic-Client Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_15") echo "Executing test case "VSDM-A_2678-15 ReadVSD ohne Authentifizierung Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2678_16") echo "Executing test case "VSDM-A_2678-16 ReadKVK ohne Authentifizierung Schlechtfall" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2678_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2682_01") echo "Executing test case "VSDM-A_2682-01  - - Keine Protokollierung von Schluesselmaterial \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2682_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_01") echo "Executing test case "VSDM-A_2689-01  - - ReadVSD - Ungültiger Aufrufkontext - WorkplaceId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_02") echo "Executing test case "VSDM-A_2689-02  - - ReadKVK - Ungueltiger Aufrufkontext - MandantId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_03") echo "Executing test case "VSDM-A_2689-03  - - ReadVSD - Ungueltiges eGK-CardHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_04") echo "Executing test case "VSDM-A_2689-04  - - ReadVSD - Ungueltiges HPC-CardHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_05") echo "Executing test case "VSDM-A_2689-05  - - ReadKVK - Ungueltiges KVK-CardHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_06") echo "Executing test case "VSDM-A_2689-06  - - ReadVSD - Ungültiger Aufrufkontext - ClientSystemId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_07") echo "Executing test case "VSDM-A_2689-07  - - ReadVSD - Ungültiger Aufrufkontext - MandantId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_08") echo "Executing test case "VSDM-A_2689-08  - - ReadKVK - Ungueltiger Aufrufkontext - WorkplaceId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2689_09") echo "Executing test case "VSDM-A_2689-09  - - ReadKVK - Ungueltiger Aufrufkontext - ClientSystemId falsch" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2689_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2690_01") echo "Executing test case "VSDM-A_2690-01  - - Fehlercode bei nicht konsistenten VSD" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2690_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2691_01") echo "Executing test case "VSDM-A_2691-01 ReadVSD - Format der Ausgangsparameter" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2691_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2692_01") echo "Executing test case "VSDM-A_2692-01 Lesen der VSD scheitert" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2692_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2692_02") echo "Executing test case "VSDM-A_2692-02 Dekomprimieren der VSD scheitert" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2692_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_01") echo "Executing test case "VSDM-A_2693-01 ReadVSD-Aufruf ohne EhcHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_02") echo "Executing test case "VSDM-A_2693-02 ReadVSD-Aufruf ohne HpcHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_03") echo "Executing test case "VSDM-A_2693-03 ReadVSD-Aufruf ohne PerformOnlineCheck" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_04") echo "Executing test case "VSDM-A_2693-04 ReadVSD-Aufruf ohne ReadOnlineReceipt" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_05") echo "Executing test case "VSDM-A_2693-05 ReadVSD-Aufruf ohne Context" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_06") echo "Executing test case "VSDM-A_2693-06 ReadVSD-Aufruf mit Context ohne MandantId" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_07") echo "Executing test case "VSDM-A_2693-07 ReadVSD-Aufruf mit Context ohne ClientSystemId" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_08") echo "Executing test case "VSDM-A_2693-08 ReadVSD-Aufruf mit Context ohne WorkplaceId" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_09") echo "Executing test case "VSDM-A_2693-09 ReadVSD-Aufruf mit Context ohne UserId" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2693_10") echo "Executing test case "VSDM-A_2693-10 ReadVSD-Aufruf mit alle Parameter" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2693_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2695_01") echo "Executing test case "VSDM-A_2695-01  - - Lesen der KVK-Daten scheitert" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2695_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2696_01") echo "Executing test case "VSDM-A_2696-01  - - KVK mit fehlerhafter Prüfsumme" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2696_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2703_01") echo "Executing test case "VSDM-A_2703-01  - - Header-Elemente bei ReadVSDResponse" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2703_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2703_02") echo "Executing test case "VSDM-A_2703-02  - - Header-Elemente bei ReadKVKResponse" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2703_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2936_01") echo "Executing test case "VSDM-A_2936-01  - - Prüfungsnachweis nicht entschlüsselbar" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2936_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2937_01") echo "Executing test case "VSDM-A_2937-01  - - Prüfungsnachweis nicht vorhanden" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2937_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2982_01") echo "Executing test case "VSDM-A_2982-01  - - SM-B nicht freigeschaltet" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2982_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2983_01") echo "Executing test case "VSDM-A_2983-01  - - HBA nicht freigeschaltet" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2983_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2608_01") echo "Executing test case "VSDM-A_2608-01  - - Aussenverhalten bei ReadKVK" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2608_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2677_01") echo "Executing test case "VSDM-A_2677-01 - - ReadKVK gegen WSDL prüfen" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2677_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2710_01") echo "Executing test case "VSDM-A_2710-01  - - ReadKVK ohne Context" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2710_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2710_02") echo "Executing test case "VSDM-A_2710-02  - - ReadKVK ohne KVKHandle" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2710_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2710_03") echo "Executing test case "VSDM-A_2710-03  - - ReadKVK ohne Parameter" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2710_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2710_04") echo "Executing test case "VSDM-A_2710-04  - - ReadKVK" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2710_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2711_01") echo "Executing test case "VSDM-A_2711-01  - - ReadKVK Ausgangsparameter" ..."
		TestFaelle/03_Paket3/03_02_Schnittstellenspezifikation_Primaersysteme_VSDM/03_02_01_Schnittstellenspezifikation_Primaersystem_VSDM/VSDM_A_2711_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2189_01") echo "Executing test case "VSDM-A_2189-01 Fachmodul VSDM - WS-I Basic Profile in der Version 1.2 umsetzen" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2189_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2190_01") echo "Executing test case "VSDM-A_2190-01 Fachmodul VSDM kommuniziert schemakonform mit UFS und CCS" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2190_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2194_01") echo "Executing test case "VSDM-A_2194-01 Authentifizierung des Fachmoduls VSDM gegenüber Intermediär" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2194_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2199_01") echo "Executing test case "VSDM-A_2199-01 Fachdienst UFS unterstützt HTTP-Komprimierung" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2199_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2199_02") echo "Executing test case "VSDM-A_2199-02 Fachdienst UFS unterstützt keine HTTP-Komprimierung" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2199_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2199_03") echo "Executing test case "VSDM-A_2199-03 Fachdienst VSD unterstützt HTTP-Komprimierung" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2199_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2199_04") echo "Executing test case "VSDM-A_2199-04 Fachdienst VSD unterstützt keine HTTP-Komprimierung" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2199_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2200_01") echo "Executing test case "VSDM-A_2200-01 HTTP-Komprimierung mit gzip - UFS" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2200_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2200_02") echo "Executing test case "VSDM-A_2200-02 HTTP-Komprimierung mit gzip - VSD" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2200_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2202_01") echo "Executing test case "VSDM-A_2202-01 Fachmodul VSDM - nur spezifizierte Header-Elemente zu Fachdiensten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2202_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2203_01") echo "Executing test case "VSDM-A_2203-01 Keine Whitespaces in Requests an Fachdienste" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2203_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2204_01") echo "Executing test case "VSDM-A_2204-01 Valide Antwortnachrichten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2204_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2204_02") echo "Executing test case "VSDM-A_2204-02 Schema-invalide GetUpdateFlagsResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2204_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2204_03") echo "Executing test case "VSDM-A_2204-03 Schema-invalide PerformUpdatesResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2204_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2204_04") echo "Executing test case "VSDM-A_2204-04 Schema-invalide GetNextCommandPackageResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2204_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2205_01") echo "Executing test case "VSDM-A_2205-01 Schema-invalide GetUpdateFlagsResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2205_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2205_02") echo "Executing test case "VSDM-A_2205-02 Schema-invalide PerformUpdatesResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2205_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2205_03") echo "Executing test case "VSDM-A_2205-03 Schema-invalide GetNextCommandPackageResponse" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2205_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2206_01") echo "Executing test case "VSDM-A_2206-01 Fachmodul VSDM validiert Antwort auf zulaessige Werte" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2206_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2207_01") echo "Executing test case "VSDM-A_2207-01 Zusätzliche Header in Antwortnachrichten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2207_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2207_02") echo "Executing test case "VSDM-A_2207-02 Zusätzliche Body-Elemente in Antwortnachrichten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2207_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2208_01") echo "Executing test case "VSDM-A_2208-01 Antwort-Header in beliebiger Reihenfolge" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2208_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2209_01") echo "Executing test case "VSDM-A_2209-01 Fachmodul VSDM bildet korrekte Lokalisierungsinformationen" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2209_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2211_01") echo "Executing test case "VSDM-A_2211-01 Fachmodul VSDM bildet korrekte ServiceLocalization-Elemente" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2211_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2212_01") echo "Executing test case "VSDM-A_2212-01 Fachmodul VSDM SessionIdentifier-Header bei PerformUpdates" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2212_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2212_02") echo "Executing test case "VSDM-A_2212-02 Fachmodul VSDM SessionIdentifier-Header bei PerformUpdates" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2212_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2213_01") echo "Executing test case "VSDM-A_2213-01 Fachmodul VSDM - SOAP Faults ohne gematik-Fehlerstruktur verarbeiten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2213_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2213_02") echo "Executing test case "VSDM-A_2213-02 SOAP-Fault ohne gematik-Fehlerstruktur vom CCS" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2213_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2214_01") echo "Executing test case "VSDM-A_2214-01 Fachmodul VSDM - HTTP-Fehlermeldungen verarbeiten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2214_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2214_02") echo "Executing test case "VSDM-A_2214-02 HTTP-Fehlermeldungen vom CCS verarbeiten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2214_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2215_01") echo "Executing test case "VSDM-A_2215-01 Fachmodul VSDM - HTTP-Fehler vom Fachdienst" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2215_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2215_02") echo "Executing test case "VSDM-A_2215-02 Fachmodul VSDM - HTTP-Fehler vom Intermediär" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2215_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2216_01") echo "Executing test case "VSDM-A_2216-01 Fachmodul VSDM - gematik SOAP Fault verarbeiten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2216_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2216_02") echo "Executing test case "VSDM-A_2216-02 gematik SOAP Fault vom CCS verarbeiten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2216_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2217_01") echo "Executing test case "VSDM-A_2217-01 Fachmodul VSDM - Nachrichten grundsaetzlich nicht speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2217_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_3033_01") echo "Executing test case "VSDM-A_3033-01 Fachmodul VSDM - kein Pruefungsnachweis wenn Online nicht aktiviert" ..."
		TestFaelle/02_Paket2/02_01_VSDM/02_01_04_Schnittstellen-Spec_Fachdienste_Fachmodul_VSDM/VSDM_A_3033_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2218_01") echo "Executing test case "VSDM-A_2218-01 Fachmodul VSDM - SOAP Faults ohne gematik-Fehlerstruktur speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2218_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2218_02") echo "Executing test case "VSDM-A_2218-02 Fachmodul VSDM - HTTP-Fehler speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2218_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2218_03") echo "Executing test case "VSDM-A_2218-03 Fachmodul VSDM - gematik SOAP Fault speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2218_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2219_01") echo "Executing test case "VSDM-A_2219-01 Fachmodul VSDM - Anfragenachricht zu SOAP Faults ohne gematik-Fehlerstruktur speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2219_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2219_02") echo "Executing test case "VSDM-A_2219-02 Fachmodul VSDM - Anfragenachricht zu HTTP-Fehler speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2219_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2219_03") echo "Executing test case "VSDM-A_2219-03 Fachmodul VSDM - Anfragenachricht zu gematik SOAP Fault speichern" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2219_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2225_01") echo "Executing test case "VSDM-A_2225-01 TLS-Session Resumption zwischen Fachmodul VSDM und Intermediär" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2225_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2226_01") echo "Executing test case "VSDM-A_2226-01 TLS-Verbindung zwischen Fachmodul VSDM und Intermediär offen halten" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2226_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2235_01") echo "Executing test case "VSDM-A_2235-01 Fachmodul VSDM - korrekte Trennzeichen in der URL" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2235_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2312_01") echo "Executing test case "VSDM-A_2312-01 Fachmodul VSDM toleriert fehlerhafte Werte in nicht verarbeiteten Elementen" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2312_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2951_01") echo "Executing test case "VSDM-A_2951-01 Performance-Logging ReadKVK" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2951_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2951_02") echo "Executing test case "VSDM-A_2951-02 Performance-Logging ReadVSD  GetUpdateFlags PerformUpdates  GetNextCommandPackage" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2951_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_2956_01") echo "Executing test case "VSDM-A_2956-01 Generische Fehlermeldungen bei fehlerhaftem Nachrichtenschema" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2956_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"VSDM_A_3003_01") echo "Executing test case "VSDM-A_3003-01 Verschluesselter Transport durch Fachmodul VSDM" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_3003_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_3070_01") echo "Executing test case "VSDM-A_3070-01 Speichern der ICCSN im VSDM-Fehlerprotokoll - UFS-Fehler" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_3070_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_3070_03") echo "Executing test case "VSDM-A_3070-03 Speichern der ICCSN im VSDM-Fehlerprotokoll - Intermediär-Fehler" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_3070_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

        "VSDM_A_2226_02") echo "Executing test case "VSDM-A_2226-02 Konfigurierbarer Timeout - interaktiv" ..."
		TestFaelle/03_Paket3/03_03_Schnittstellenspezifikation_Transport_VSDM/03_03_01_Schnittstellenspezifikation_Transport_VSDM/VSDM_A_2226_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4350_01") echo "Executing test case "TIP1-A_4350-01 VPN-Zugangsdienst und Konnektor  ESP" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4350_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4351_01") echo "Executing test case "TIP1-A_4351-01 Abschaltung der Sequenznummer-Auswertung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4351_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4352_01") echo "Executing test case "TIP1-A_4352-01 Fenster fuer die Auswertung der Sequenznummern \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4352_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4353_01") echo "Executing test case "TIP1-A_4353-01 VPN-Zugangsdienst und Konnektor Internet Key Exchange Version 2" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4353_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4354_01") echo "Executing test case "TIP1-A_4354-01 VPN-Zugangsdienst und Konnektor NAT-Traversal" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4354_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4355_01") echo "Executing test case "TIP1-A_4355-01 VPN-Zugangsdienst und Konnektor  Dynamic Address Update" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4355_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4356_01") echo "Executing test case "TIP1-A_4356-01 VPN-Zugangsdienst und Konnektor  IP Payload Compression Protocol" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4356_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4357_01") echo "Executing test case "TIP1-A_4357-01 VPN-Zugangsdienst und Konnektor  Peer Liveness Detection" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4357_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4358_01") echo "Executing test case "TIP1-A_4358-01 Konnektor  Liveness Check Konnektor Zeitablauf \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4358_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4359_01") echo "Executing test case "TIP1-A_4359-01 Konnektor  NAT-Keepalives \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4359_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4360_01") echo "Executing test case "TIP1-A_4360-01 Konnektor  Konfiguration der NAT-Keepalives im Konnektor \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4360_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4373_01") echo "Executing test case "TIP1-A_4373-01 Konnektor  TUC_VPN-ZD_0001 -IPsec-Tunnel TI aufbauen-" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4373_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4373_02") echo "Executing test case "TIP1-A_4373-02 Konnektor  TUC_VPN-ZD_0001 -AUTHENTICATION_FAILED-" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4373_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4374_01") echo "Executing test case "TIP1-A_4374-01 VPN-Zugangsdienst  Verbindungsaufbau" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4374_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4375_01") echo "Executing test case "TIP1-A_4375-01 SIS-VPN erneut aufbauen" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4375_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4376_01") echo "Executing test case "TIP1-A_4376-01 VPN_TI - SRV-Records und TTL \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4376_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4376_02") echo "Executing test case "TIP1-A_4376-02 VPN_TI - Priorität und Gewichtung von SRV-Records" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4376_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4376_03") echo "Executing test case "TIP1-A_4376-03 VPN_SIS - SRV-Records und TTL \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4376_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4376_04") echo "Executing test case "TIP1-A_4376-04 VPN_SIS - Priorität und Gewichtung von SRV-Records" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4376_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4377_01") echo "Executing test case "TIP1-A_4377-01 VPN_TI - Namensaufloesung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4377_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4377_02") echo "Executing test case "TIP1-A_4377-02 VPN_SIS - Namensaufloesung \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4377_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4397_01") echo "Executing test case "TIP1-A_4397-01  - - Konnektor" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4397_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4397_02") echo "Executing test case "TIP1-A_4397-02  - - Konnektor" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4397_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4491_01") echo "Executing test case "TIP1-A_4491-01 VPN-Zugangsdienst" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4491_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4353_02") echo "Executing test case "TIP1-A_4353-02 VPN-Zugangsdienst und Konnektor" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4353_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4353_03") echo "Executing test case "TIP1-A_4353-03 VPN-Zugangsdienst und Konnektor" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4353_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4354_02") echo "Executing test case "TIP1-A_4354-02 NAT-Traversal wird genutzt" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4354_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4373_03") echo "Executing test case "TIP1-A_4373-03 TUC_VPN-ZD-0001 \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4373_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4397_03") echo "Executing test case "TIP1-A_4397-03 TUC_VPN-ZD-0002 \(interaktiv\)" ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4397_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4560_01") echo "Executing test case "TIP1-A_4560-01 Rahmenbedingungen fuer Kartensitzungen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4560_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4560_02") echo "Executing test case "TIP1-A_4560-02 Rahmenbedingungen fuer Kartensitzungen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4560_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4560_03") echo "Executing test case "TIP1-A_4560-03 Rahmenbedingungen fuer Kartensitzungen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4560_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4560_04") echo "Executing test case "TIP1-A_4560-04 Rahmenbedingungen fuer Kartensitzungen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4560_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4585_01") echo "Executing test case "TIP1-A_4585-01 TUC_KON_216 LeseZertifikat" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4585_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4586_01") echo "Executing test case "TIP1-A_4586-01  - - Basisanwendung Kartendienst" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4586_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4592_01") echo "Executing test case "TIP1-A_4592-01  - - Konfigurationswerte des Kartendienstes \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4592_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4592_02") echo "Executing test case "TIP1-A_4592-02 Defaultwerte \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4592_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4593_01") echo "Executing test case "TIP1-A_4593-01 TUC_KON_025 Initialisierung Kartendienst" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4593_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_101") echo "Executing test case "TIP1-A_4988-101  - - Unterstützung von Gen1 und Gen2 Karten \(eGK G1+\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_101.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_201") echo "Executing test case "TIP1-A_4988-201  - - Unterstützung von Gen1 und Gen2 Karten \(eGK G1\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_201.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_301") echo "Executing test case "TIP1-A_4988-301  - - Unterstützung von Gen1 und Gen2 Karten \(eGK G2\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_301.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_302") echo "Executing test case "TIP1-A_4988-302  - - Unterstützung von Gen1 und Gen2 Karten \(HBA\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_302.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_303") echo "Executing test case "TIP1-A_4988-303  - - Unterstützung von Gen1 und Gen2 Karten \(SMC-B\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_303.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_304") echo "Executing test case "TIP1-A_4988-304  - - Unterstützung von Gen1 und Gen2 Karten \(gSMC-KT\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_304.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4988_501") echo "Executing test case "TIP1-A_4988-501 Unterstützung von Gen1 und Gen2 Karten \(C2C-Authentisierung gSMC-KT mit HBA\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_4988_501.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5110_01") echo "Executing test case "TIP1-A_5110-01 Uebersicht ueber alle verfuegbaren Karten -" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5110_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5110_02") echo "Executing test case "TIP1-A_5110-02 Uebersicht ueber alle verfuegbaren Karten -weitere Details-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5110_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5110_03") echo "Executing test case "TIP1-A_5110-03 Uebersicht ueber alle verfuegbaren Karten -KVK-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5110_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5111_01") echo "Executing test case "TIP1-A_5111-01 PIN-Management der SM-Bs für den Administrator - TUC_KON_012 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5111_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5111_02") echo "Executing test case "TIP1-A_5111-02 PIN-Management der SM-Bs für den Administrator - TUC_KON_019 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5111_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5111_03") echo "Executing test case "TIP1-A_5111-03 PIN-Management der SM-Bs für den Administrator - TUC_KON_021 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5111_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5111_04") echo "Executing test case "TIP1-A_5111-04 PIN-Management der SM-Bs für den Administrator - TUC_KON 022 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_00_Allgemein/TIP1_A_5111_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_01") echo "Executing test case "TIP1-A_4561-01  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Verifikation HBA\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_02") echo "Executing test case "TIP1-A_4561-02  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Verifikation SMC-B\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_03") echo "Executing test case "TIP1-A_4561-03  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung SMC-B - PIN.SMC\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_04") echo "Executing test case "TIP1-A_4561-04  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung HBA - PIN.CH\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_05") echo "Executing test case "TIP1-A_4561-05  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung HBA - PIN.QES\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_06") echo "Executing test case "TIP1-A_4561-06  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung EGK - PIN.CH\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_07") echo "Executing test case "TIP1-A_4561-07  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung SMC-B - PIN.CONF\) - obsolet" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_08") echo "Executing test case "TIP1-A_4561-08  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung EGK - Transport PIN\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_09") echo "Executing test case "TIP1-A_4561-09  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung HBA - Transport PIN - PIN.CH\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_10") echo "Executing test case "TIP1-A_4561-10  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung HBA - Transport PIN - PIN.QES\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_11") echo "Executing test case "TIP1-A_4561-11  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Änderung SMC-B -Transport PIN- PIN.SMC\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_12") echo "Executing test case "TIP1-A_4561-12  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Entsperren - eGK\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_13") echo "Executing test case "TIP1-A_4561-13  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Entsperren - HBA - PUK.CH\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_14") echo "Executing test case "TIP1-A_4561-14  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Entsperren - HBA - PUK.QES\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4561_15") echo "Executing test case "TIP1-A_4561-15  - - Terminal-Anzeigen für PIN-Operationen \(PIN-Entsperren - SMC-B - PUK.SMC\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4561_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4562_01") echo "Executing test case "TIP1-A_4562-01 Reaktion auf Karte entfernt" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4562_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4563_01") echo "Executing test case "TIP1-A_4563-01 Reaktion auf Karte gesteckt" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4563_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4565_01") echo "Executing test case "TIP1-A_4565-01  - - TUC_KON_001 Karte öffnen - eGK \(G2\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4565_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4566_01") echo "Executing test case "TIP1-A_4566-01  - - TUC_KON_026 Liefere CardSession" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_01_Terminal-Anzeigen/TIP1_A_4566_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_01") echo "Executing test case "TIP1-A_4567-01  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Result = OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_02") echo "Executing test case "TIP1-A_4567-02  - - TUC_KON_012 PIN verifizieren - Remote-PIN-KT - Fehlercode 4092" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_03") echo "Executing test case "TIP1-A_4567-03  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Fehlercode 4049" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_04") echo "Executing test case "TIP1-A_4567-04  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Fehlercode 4043" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_05") echo "Executing test case "TIP1-A_4567-05  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - gesperrte PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_06") echo "Executing test case "TIP1-A_4567-06  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - falsche PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_07") echo "Executing test case "TIP1-A_4567-07  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Timeout bei Kartenzugriff" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_08") echo "Executing test case "TIP1-A_4567-08  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Resource belegt" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_09") echo "Executing test case "TIP1-A_4567-09  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - Fehlercode 4065" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_10") echo "Executing test case "TIP1-A_4567-10  - - TUC_KON_012 PIN verifizieren - lokal zugeordnetes KT - falsche PIN - Blocked" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_11") echo "Executing test case "TIP1-A_4567-11  - - TUC_KON_012 PIN verifizieren - Remote-PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4567_13") echo "Executing test case "TIP1-A_4567-13  - - TUC_KON_012 PIN verifizieren - Remote-PIN - Fehler 4053" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4567_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_01") echo "Executing test case "TIP1-A_4587-01  - - Operation VerifyPin - PinResult OK - SMC-B" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_02") echo "Executing test case "TIP1-A_4587-02  - - Operation VerifyPin - Fehlercode 4209" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_03") echo "Executing test case "TIP1-A_4587-03  - - Operation VerifyPin - Fehlercode 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_04") echo "Executing test case "TIP1-A_4587-04  - - Operation VerifyPin - PinResult REJECTED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_05") echo "Executing test case "TIP1-A_4587-05  - - Operation VerifyPin - PinResult WASBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_06") echo "Executing test case "TIP1-A_4587-06  - - Operation VerifyPin - PinResult NOWBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_07") echo "Executing test case "TIP1-A_4587-07  - - Operation VerifyPin - PinResult TRANSPORT_PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_08") echo "Executing test case "TIP1-A_4587-08  - - Operation VerifyPin - Aufruf TUC_KON_000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_09") echo "Executing test case "TIP1-A_4587-09  - - Operation VerifyPin - HBA - fehlende UserID" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4587_10") echo "Executing test case "TIP1-A_4587-10  - - Operation VerifyPin - PinResult OK - HBA" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_02_PIN_verifizieren/TIP1_A_4587_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_01") echo "Executing test case "TIP1-A_4568-01  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - SMC-B - Result = OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_02") echo "Executing test case "TIP1-A_4568-02  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - entferne PinRef" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_03") echo "Executing test case "TIP1-A_4568-03  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4063" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_04") echo "Executing test case "TIP1-A_4568-04  - - TUC_KON_019 PIN ändern - remote KT" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_05") echo "Executing test case "TIP1-A_4568-05  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4049" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_06") echo "Executing test case "TIP1-A_4568-06  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4067" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_07") echo "Executing test case "TIP1-A_4568-07  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4061" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_08") echo "Executing test case "TIP1-A_4568-08  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4082" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_09") echo "Executing test case "TIP1-A_4568-09  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4043" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_10") echo "Executing test case "TIP1-A_4568-10  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4068" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_11") echo "Executing test case "TIP1-A_4568-11  - - TUC_KON_019 PIN ändern - remote KT - Fehlercode 4092" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4759_06") echo "Executing test case "TIP1-A_4759-06 Ueberlappung mit NET_TI_OFFENE_FD \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4752_02") echo "Executing test case "TIP1-A_4759-06 Ueberlappung mit NET_TI_OFFENE_FD \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4752_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;	
	
	"TIP1_A_4568_12") echo "Executing test case "TIP1-A_4568-12  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4060" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_13") echo "Executing test case "TIP1-A_4568-13  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4094" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_14") echo "Executing test case "TIP1-A_4568-14  - - TUC_KON_019 PIN ändern - eGK G1+ und Transport PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4568_15") echo "Executing test case "TIP1-A_4568-15  - - TUC_KON_019 PIN ändern - lokal zugeordnetes KT - Fehlercode 4066" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4568_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_01") echo "Executing test case "TIP1-A_4588-01  - - Operation ChangePin - Result = OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_02") echo "Executing test case "TIP1-A_4588-02  - - Operation ChangePin - Fehlercode 4209" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_03") echo "Executing test case "TIP1-A_4588-03  - - Operation ChangePin - Fehlercode 4072" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_04") echo "Executing test case "TIP1-A_4588-04  - - Operation ChangePin - Result = REJECTED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_05") echo "Executing test case "TIP1-A_4588-05  - - Operation ChangePin - Result = WASBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_06") echo "Executing test case "TIP1-A_4588-06  - - Operation ChangePin - Result = NOWBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_07") echo "Executing test case "TIP1-A_4588-07  - - Operation ChangePin - Aufruf TUC_KON_000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_08") echo "Executing test case "TIP1-A_4588-08  - - Operation ChangePin - eGK - Result = OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_09") echo "Executing test case "TIP1-A_4588-09  - - Operation ChangePin - HBA PIN.CH - Result = OK - mit UserID" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_10") echo "Executing test case "TIP1-A_4588-10  - - Operation ChangePin - HBA PIN.QES - Result = OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4588_11") echo "Executing test case "TIP1-A_4588-11  - - Operation ChangePin - Fehlercode 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_03_PIN_aendern/TIP1_A_4588_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_01") echo "Executing test case "TIP1-A_4569-01 TUC_KON_021 PIN entsperren - neue PIN - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_02") echo "Executing test case "TIP1-A_4569-02 TUC_KON_021 PIN entsperren - neue PIN - CardTimeout" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_03") echo "Executing test case "TIP1-A_4569-03 TUC_KON_021 PIN entsperren - neue PIN - PUK falsch" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_04") echo "Executing test case "TIP1-A_4569-04 TUC_KON_021 PIN entsperren - neue PIN - PUK blocked" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_05") echo "Executing test case "TIP1-A_4569-05 TUC_KON_021 PIN entsperren - neue PIN - Neue PIN nicht identisch" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_06") echo "Executing test case "TIP1-A_4569-06 TUC_KON_021 PIN entsperren - neue PIN - PIN-Länge falsch" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_07") echo "Executing test case "TIP1-A_4569-07 TUC_KON_021 PIN entsperren - neue PIN - PIN-Timeout" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_08") echo "Executing test case "TIP1-A_4569-08 TUC_KON_021 PIN entsperren - neue PIN - Abbruch" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_09") echo "Executing test case "TIP1-A_4569-09 TUC_KON_021 PIN entsperren - neue PIN - Resource belegt" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_10") echo "Executing test case "TIP1-A_4569-10 TUC_KON_021 PIN entsperren - ohne PIN - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_11") echo "Executing test case "TIP1-A_4569-11 TUC_KON_021 PIN entsperren - neue PIN - remote PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_12") echo "Executing test case "TIP1-A_4569-12 TUC_KON_021 PIN entsperren - neue PIN - kein Remote-KT" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4569_13") echo "Executing test case "TIP1-A_4569-13 TUC_KON_021 PIN entsperren - neue PIN - PUK falsch - dadurch blockiert" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4569_14") echo "Executing test case "TIP1-A_4569-14 TUC_KON_021 PIN entsperren - neue PIN - eGK G1+" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4569_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_01") echo "Executing test case "TIP1-A_4590-01  - - Operation UnblockPin - PinResult OK - eGK - Parameter SetNewPin" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_02") echo "Executing test case "TIP1-A_4590-02  - - Operation UnblockPin - PinResult REJECTED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_03") echo "Executing test case "TIP1-A_4590-03  - - Operation UnblockPin - PinResult OK - eGK - ohne Parameter SetNewPin" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_04") echo "Executing test case "TIP1-A_4590-04  - - Operation UnblockPin - PinResult NOWBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_05") echo "Executing test case "TIP1-A_4590-05  - - Operation UnblockPin - PinResult WASBLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_06") echo "Executing test case "TIP1-A_4590-06  - - Operation UnblockPin - Fehlercode 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_07") echo "Executing test case "TIP1-A_4590-07  - - Operation UnblockPin - Aufruf TUC_KON_000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_08") echo "Executing test case "TIP1-A_4590-08  - - Operation UnblockPin - Fehlercode 4209" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_09") echo "Executing test case "TIP1-A_4590-09  - - Operation UnblockPin - ohne PIN - HBA PIN.CH" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_10") echo "Executing test case "TIP1-A_4590-10  - - Operation UnblockPin - ohne PIN - HBA PIN.QES" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4590_11") echo "Executing test case "TIP1-A_4590-11  - - Operation UnblockPin - ohne PIN - SMC-B PIN.SMC" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_04_PIN_entsperren/TIP1_A_4590_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_01") echo "Executing test case "TIP1-A_4570-01 TUC_KON_022 Liefere PIN-Status" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_02") echo "Executing test case "TIP1-A_4570-02 TUC_KON_022 Liefere PIN-Status -LeerPIN-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_03") echo "Executing test case "TIP1-A_4570-03 TUC_KON_022 Liefere PIN-Status -TransportPIN-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_05") echo "Executing test case "TIP1-A_4570-05 TUC_KON_022 Liefere PIN-Status -falsche Pin-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_06") echo "Executing test case "TIP1-A_4570-06 TUC_KON_022 Liefere PIN-Status -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4570_04") echo "Executing test case "TIP1-A_4570-04 TUC_KON_022 Liefere PIN-Status -Fehlercode 4072-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4570_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_01") echo "Executing test case "TIP1-A_4589-01  - - Operation GetPinStatus eGK - PIN.CH" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_02") echo "Executing test case "TIP1-A_4589-02  - - Operation GetPinStatus SMC-B - PIN.SMC - Status = VERIFIED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_03") echo "Executing test case "TIP1-A_4589-03  - - Operation GetPinStatus HBA - PIN.CH - Status = TRANSPORT_PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_04") echo "Executing test case "TIP1-A_4589-04  - - Operation GetPinStatus HBA - PIN.QES - Status = BLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_05") echo "Executing test case "TIP1-A_4589-05  - - Operation GetPinStatus eGK G1+ - PIN.CH = Leer-PIN" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_06") echo "Executing test case "TIP1-A_4589-06  - - Operation GetPinStatus - Fehlercode 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_07") echo "Executing test case "TIP1-A_4589-07  - - Operation GetPinStatus - Aufruf TUC_KON_000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_08") echo "Executing test case "TIP1-A_4589-08  - - Operation GetPinStatus - Fehlercode 4047" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_09") echo "Executing test case "TIP1-A_4589-09  - - Operation GetPinStatus - Fehlercode 4072" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_10") echo "Executing test case "TIP1-A_4589-10  - - Operation GetPinStatus - Fehlercode 4209" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4589_11") echo "Executing test case "TIP1-A_4589-11  - - Operation GetPinStatus - Fehlercode 4046" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_05_PIN-Status/TIP1_A_4589_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_01") echo "Executing test case "TIP1-A_5012-01  - - Remote-PIN-Verfahren - PIN.CH HBA" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_02") echo "Executing test case "TIP1-A_5012-02  - - Remote-PIN-Verfahren - PIN.QES HBA" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_03") echo "Executing test case "TIP1-A_5012-03  - - Remote-PIN-Verfahren - PUK.QES HBA" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_04") echo "Executing test case "TIP1-A_5012-04  - - Remote-PIN-Verfahren - PUK.CH HBA" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_05") echo "Executing test case "TIP1-A_5012-05  - - Remote-PIN-Verfahren - PIN.SMC SMC-B" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_06") echo "Executing test case "TIP1-A_5012-06  - - Remote-PIN-Verfahren - PUK.SMC SMC-B" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5012_07") echo "Executing test case "TIP1-A_5012-07  - - Remote-PIN-Verfahren - Fehlercode 4053" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_06_Remote_PIN/TIP1_A_5012_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4591_01") echo "Executing test case "TIP1-A_4591-01  - - Operation AuthorizeSMC - Fehlercode 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_07_Authorize_SMC/TIP1_A_4591_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4591_02") echo "Executing test case "TIP1-A_4591-02  - - Operation AuthorizeSMC - Aufruf TUC_KON_000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_07_Authorize_SMC/TIP1_A_4591_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4591_03") echo "Executing test case "TIP1-A_4591-03  - - Operation AuthorizeSMC - Fehlercode 4051" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_07_Authorize_SMC/TIP1_A_4591_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4591_04") echo "Executing test case "TIP1-A_4591-04  - - Operation AuthorizeSMC - Status OK \(HBA - SMC-B\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_07_Authorize_SMC/TIP1_A_4591_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_01") echo "Executing test case "TIP1-A_4572-01 TUC_KON_005 Card-to-Card authentisieren \(einseitig\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_02") echo "Executing test case "TIP1-A_4572-02 TUC_KON_005 Card-to-Card authentisieren \(gegenseitig\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_03") echo "Executing test case "TIP1-A_4572-03 TUC_KON_005 Card-to-Card authentisieren \(gegenseitig+TC\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_04") echo "Executing test case "TIP1-A_4572-04 TUC_KON_005 Card-to-Card authentisieren \(Cross-CVC\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_05") echo "Executing test case "TIP1-A_4572-05 TUC_KON_005 Card-to-Card authentisieren - CardTimeout" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_06") echo "Executing test case "TIP1-A_4572-06 TUC_KON_005 Card-to-Card authentisieren - Fehler 4233" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_07") echo "Executing test case "TIP1-A_4572-07 TUC_KON_005 Card-to-Card authentisieren - G1 nicht mehr unterstützt \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4572_08") echo "Executing test case "TIP1-A_4572-08 TUC_KON_005 Card-to-Card authentisieren \(Cross-CV-Zertifikat nicht vorhanden\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_08_Card-to-Card_authezieren/TIP1_A_4572_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_01") echo "Executing test case "TIP1-A_4573-01 TUC_KON_202 LeseDatei" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_02") echo "Executing test case "TIP1-A_4573-02 TUC_KON_202 Lese Datei -Fehlercode 4085" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_03") echo "Executing test case "TIP1-A_4573-03 TUC_KON_202 Lese Datei -Fehlercode 4093- \(aktuell nicht testbar\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_04") echo "Executing test case "TIP1-A_4573-04 TUC_KON_202 Lese Datei -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_05") echo "Executing test case "TIP1-A_4573-05 TUC_KON_202 Lese Datei -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_06") echo "Executing test case "TIP1-A_4573-06 TUC_KON_202 Lese Datei -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4573_07") echo "Executing test case "TIP1-A_4573-07 TUC_KON_202 Lese Datei -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4573_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_01") echo "Executing test case "TIP1-A_4574-01 TUC_KON_203 SchreibeDatei" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_02") echo "Executing test case "TIP1-A_4574-02 TUC_KON_203 SchreibeDatei -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_03") echo "Executing test case "TIP1-A_4574-03 TUC_KON_203 SchreibeDatei -Fehlercode 4085-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_04") echo "Executing test case "TIP1-A_4574-04 TUC_KON_203 SchreibeDatei -Fehlercode 4093- \(aktuell nicht testbar\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_05") echo "Executing test case "TIP1-A_4574-05 TUC_KON_203 SchreibeDatei -Fehlercode 4085-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_06") echo "Executing test case "TIP1-A_4574-06 TUC_KON_203 SchreibeDatei -Fehlercode 4087-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_07") echo "Executing test case "TIP1-A_4574-07 TUC_KON_203 SchreibeDatei -Fehlercode 4087-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_08") echo "Executing test case "TIP1-A_4574-08 TUC_KON_203 SchreibeDatei -Fehlercode 4089-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_09") echo "Executing test case "TIP1-A_4574-09 TUC_KON_203 SchreibeDatei -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4574_10") echo "Executing test case "TIP1-A_4574-10 TUC_KON_203 SchreibeDatei -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4574_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_01") echo "Executing test case "TIP1-A_4575-01 TUC_KON_209 LeseRecord - \(aktuell nicht testbar\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_02") echo "Executing test case "TIP1-A_4575-02 TUC_KON_209 LeseRecord -Fehlercode 4085-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_03") echo "Executing test case "TIP1-A_4575-03 TUC_KON_209 LeseRecord -Fehlercode 4087-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_04") echo "Executing test case "TIP1-A_4575-04 TUC_KON_209 LeseRecord -Fehlercode 4089-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_05") echo "Executing test case "TIP1-A_4575-05 TUC_KON_209 LeseRecord -Fehlercode 4093- \(aktuell nicht testbar\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_06") echo "Executing test case "TIP1-A_4575-06 TUC_KON_209 LeseRecord -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4575_07") echo "Executing test case "TIP1-A_4575-07 TUC_KON_209 LeseRecord -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4575_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_01") echo "Executing test case "TIP1-A_4577-01 TUC_KON_214 FuegeHinzuRecord" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_02") echo "Executing test case "TIP1-A_4577-02 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4085-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_03") echo "Executing test case "TIP1-A_4577-03 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_04") echo "Executing test case "TIP1-A_4577-04 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4085-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_05") echo "Executing test case "TIP1-A_4577-05 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4093- \(aktuell nicht testbar\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_06") echo "Executing test case "TIP1-A_4577-06 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4087-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_07") echo "Executing test case "TIP1-A_4577-07 TUC_KON_214 FuegeHinzuRecord -Fehlercode 4087-Testfall gelöscht" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4577_08") echo "Executing test case "TIP1-A_4577-08 TUC_KON_214 FuegeHinzuRecord -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4577_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4579_01") echo "Executing test case "TIP1-A_4579-01 TUC_KON_018 eGK-Sperrung pruefen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4579_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4580_01") echo "Executing test case "TIP1-A_4580-01 TUC_KON_006 Datenzugriffsaudit eGK schreiben" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4580_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_01") echo "Executing test case "TIP1-A_4583-01  - - TUC_KON_200 SendeAPDU" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_02") echo "Executing test case "TIP1-A_4583-02  - - TUC_KON_200 SendeAPDU -ReadVSD AutoUpdateVSD-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_03") echo "Executing test case "TIP1-A_4583-03  - - TUC_KON_200 SendeAPDU -Perform Verification-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_04") echo "Executing test case "TIP1-A_4583-04  - - TUC_KON_200 SendeAPDU -Kartenterminalkommando-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_05") echo "Executing test case "TIP1-A_4583-05  - - TUC_KON_200 SendeAPDU -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_06") echo "Executing test case "TIP1-A_4583-06  - - TUC_KON_200 SendeAPDU -Fehlercode 4232-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_07") echo "Executing test case "TIP1-A_4583-07  - - TUC_KON_200 SendeAPDU -Fehlercode 4044-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_08") echo "Executing test case "TIP1-A_4583-08  - - TUC_KON_200 SendeAPDU -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4583_09") echo "Executing test case "TIP1-A_4583-09  - - TUC_KON_200 SendeAPDU -Kartenfehler-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4583_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_01") echo "Executing test case "TIP1-A_4584-01 TUC_KON_024 Karte zuruecksetzen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_02") echo "Executing test case "TIP1-A_4584-02 TUC_KON_024 Karte zuruecksetzen - Testfall gelöscht" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_03") echo "Executing test case "TIP1-A_4584-03 TUC_KON_024 Karte zuruecksetzen -Fehlercode 4094-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_04") echo "Executing test case "TIP1-A_4584-04 TUC_KON_024 Karte zuruecksetzen -Fehlercode 4232-" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_05") echo "Executing test case "TIP1-A_4584-05 TUC_KON_024 Karte zuruecksetzen - Kartenfehler" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4584_06") echo "Executing test case "TIP1-A_4584-06 TUC_KON_024 Karte zuruecksetzen - Kartenfehler" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_01_Kartendienst/04_01_01_09_Datenzugriff/TIP1_A_4584_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4719_01") echo "Executing test case "TIP1-A_4719-01 TLS-Dienst reagiert auf Veraenderung LU_ONLINE Active = Ja" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4719_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4719_02") echo "Executing test case "TIP1-A_4719-02 TLS-Dienst reagiert auf Veraenderung LU_ONLINE Active = Nein" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4719_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4720_01") echo "Executing test case "TIP1-A_4720-01 TUC_KON_110 Kartenbasierte TLS-Verbindung aufbauen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4720_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4720_02") echo "Executing test case "TIP1-A_4720-02 TUC_KON_110 Kartenbasierte TLS-Verbindung aufbauen Fehlercode = 4156" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4720_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4720_03") echo "Executing test case "TIP1-A_4720-03 TUC_KON_110 Kartenbasierte TLS-Verbindung aufbauen Fehlercode = 4157" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4720_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4720_04") echo "Executing test case "TIP1-A_4720-04 TUC_KON_110 Kartenbasierte TLS-Verbindung aufbauen Fehlercode = 4220" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4720_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4721_01") echo "Executing test case "TIP1-A_4721-01 TUC_KON_111 Kartenbasierte TLS-Verbindung abbauen" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4721_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4721_02") echo "Executing test case "TIP1-A_4721-02 TUC_KON_111 Kartenbasierte TLS-Verbindung abbauen Fehlercode = 4158" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4721_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4722_01") echo "Executing test case "TIP1-A_4722-01 TLS-Dienst initialisieren MGM_LU_ONLINE = Enabled" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4722_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4722_02") echo "Executing test case "TIP1-A_4722-02 TLS-Dienst initialisieren MGM_LU_ONLINE = Disabled" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_02_TLS-Dienst/04_01_02_01_TLS-Dienst/TIP1_A_4722_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4682_01") echo "Executing test case "TIP1-A_4682-01 Sicheres Einbringen des TI-Vertrauensankers - mit gSMC-K" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4682_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4682_02") echo "Executing test case "TIP1-A_4682-02 Sicheres Einbringen des TI-Vertrauensankers - Zugriffsfehler auf gSMC-K" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4682_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4683_01") echo "Executing test case "TIP1-A_4683-01 Sicheres Einbringen des QES-Vertrauensankers - mit gSMC-K" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4683_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4683_02") echo "Executing test case "TIP1-A_4683-02 Sicheres Einbringen des QES-Vertrauensankers - ohne gSMC-K \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4683_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4684_01") echo "Executing test case "TIP1-A_4684-01 Regelmässige Aktualisierung der CRL und der TSL" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4684_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4685_01") echo "Executing test case "TIP1-A_4685-01 Vermeidung von Spitzenlasten bei TSL-Download \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4685_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4685_02") echo "Executing test case "TIP1-A_4685-02 Vermeidung von Spitzenlasten bei CRL-Download \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4685_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4686_01") echo "Executing test case "TIP1-A_4686-01 Warnung vor Ablauf der TSL \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4686_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4686_02") echo "Executing test case "TIP1-A_4686-02 Warnung bei Ablauf der TSL innerhalb Grace-Period \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4686_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4686_03") echo "Executing test case "TIP1-A_4686-03 Warnung bei Ablauf der TSL ausserhalb Grace-Period \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4686_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4687_01") echo "Executing test case "TIP1-A_4687-01 Warnung vor Ablauf des TI-Vertrauensankers \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4687_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4687_02") echo "Executing test case "TIP1-A_4687-02 Warnung bei Ablauf des TI-Vertrauensankers \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4687_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4688_01") echo "Executing test case "TIP1-A_4688-01 OCSP-Forwarding" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4688_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4689_01") echo "Executing test case "TIP1-A_4689-01 Caching von OCSP-Antworten \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4689_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4690_01") echo "Executing test case "TIP1-A_4690-01 Timeout und Graceperiod für OCSP-Anfragen \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4690_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4691_01") echo "Executing test case "TIP1-A_4691-01 Ablauf der gSMC-K und der gesteckten Karten regelmässig prüfen \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4691_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4692_01") echo "Executing test case "TIP1-A_4692-01 Missbrauchserkennung  zu kontrollierende Operationen \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4692_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4693_01") echo "Executing test case "TIP1-A_4693-01 TUC_KON_032 TSL aktualisieren - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4693_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4693_02") echo "Executing test case "TIP1-A_4693-02 TUC_KON_032 TSL aktualisieren - Fehler 4127 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4693_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4693_04") echo "Executing test case "TIP1-A_4693-04 TUC_KON_032 TSL aktualisieren - CERT_CRL_DOWNLOAD_ADDRESS \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4693_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4694_01") echo "Executing test case "TIP1-A_4694-01 TUC_KON_040 CRL aktualisieren - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4694_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4694_02") echo "Executing test case "TIP1-A_4694-02 TUC_KON_040 CRL aktualisieren - Fehler 4130" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4694_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4695_01") echo "Executing test case "TIP1-A_4695-01 TUC_KON_033 Zertifikatsablauf prüfen - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4695_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4695_02") echo "Executing test case "TIP1-A_4695-02 TUC_KON_033 Zertifikatsablauf prüfen - Fehler 4131" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4695_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4695_03") echo "Executing test case "TIP1-A_4695-03 TUC_KON_033 Zertifikatsablauf prüfen - Fehler 4132" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4695_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4697_01") echo "Executing test case "TIP1-A_4697-01 TUC_KON_034 Zertifikatsinformationen extrahieren - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4697_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4696_01") echo "Executing test case "TIP1-A_4696-01 TUC_KON_037 Zertifikat prüfen – OK  X.509" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4696_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4696_02") echo "Executing test case "TIP1-A_4696-02 TUC_KON_037 Zertifikat prüfen - Fehler 4196" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4696_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4696_03") echo "Executing test case "TIP1-A_4696-03 TUC_KON_037 Zertifikat prüfen – OK  CVC" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4696_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4697_02") echo "Executing test case "TIP1-A_4697-02 TUC_KON_034 Zertifikatsinformationen extrahieren - Fehler 4146" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4697_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4697_03") echo "Executing test case "TIP1-A_4697-03 TUC_KON_034 Zertifikatsinformationen extrahieren - Fehler 4147" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4697_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4697_04") echo "Executing test case "TIP1-A_4697-04 TUC_KON_034 Zertifikatsinformationen extrahieren - Fehler 4148" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4697_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4698_01") echo "Executing test case "TIP1-A_4698-01 Basisanwendung Zertifikatsdienst" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4698_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4699_01") echo "Executing test case "TIP1-A_4699-01 Operation CheckCertificateExpiration - Ohne CardHandle" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4699_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4699_02") echo "Executing test case "TIP1-A_4699-02 Operation CheckCertificateExpiration - Mit CardHandle" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4699_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4699_03") echo "Executing test case "TIP1-A_4699-03 Operation CheckCertificateExpiration - Fehler 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4699_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4699_04") echo "Executing test case "TIP1-A_4699-04 Operation CheckCertificateExpiration - Fehler 4058" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4699_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4700_01") echo "Executing test case "TIP1-A_4700-01 Operation ReadCardCertificate - OK" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4700_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4700_02") echo "Executing test case "TIP1-A_4700-02 Operation ReadCardCertificate - Fehler 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4700_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4700_03") echo "Executing test case "TIP1-A_4700-03 Operation ReadCardCertificate - Fehler 4090" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4700_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4700_04") echo "Executing test case "TIP1-A_4700-04 Operation ReadCardCertificate - Fehler 4149" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4700_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4701_01") echo "Executing test case "TIP1-A_4701-01 TUC_KON_035 Zertifikatsdienst initialisieren" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4701_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4702_01") echo "Executing test case "TIP1-A_4702-01 Konfigurierbarkeit des Zertifikatsdienstes \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4702_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4703_01") echo "Executing test case "TIP1-A_4703-01 Vertrauensraumstatus anzeigen \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4703_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4704_01") echo "Executing test case "TIP1-A_4704-01 Zertifikatsablauf anzeigen \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4704_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4705_01") echo "Executing test case "TIP1-A_4705-01 TSL manuell importieren - OK \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4705_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4705_02") echo "Executing test case "TIP1-A_4705-02 TSL manuell importieren - Fehler 4128 \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4705_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4705_03") echo "Executing test case "TIP1-A_4705-03 TSL manuell importieren - Wechsel TI-Vertrauensanker \(interaktiv\) - BLOCKED" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4705_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4705_04") echo "Executing test case "TIP1-A_4705-04 TSL manuell importieren - Cross-CVC \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4705_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4705_05") echo "Executing test case "TIP1-A_4705-05 TSL manuell importieren - CVC-Root-CA \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4705_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4706_01") echo "Executing test case "TIP1-A_4706-01 CRL manuell importieren \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4706_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4994_01") echo "Executing test case "TIP1-A_4994-01 Warnung vor Ablauf der CRL \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4994_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4994_02") echo "Executing test case "TIP1-A_4994-02 Warnung nach Ablauf der CRL \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4994_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_01") echo "Executing test case "TIP1-A_5449-01 Operation VerifyCertificate - Ohne VerificationTime" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_5449_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_02") echo "Executing test case "TIP1-A_5449-02 Operation VerifyCertificate - Mit VerificationTime" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_5449_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_03") echo "Executing test case "TIP1-A_5449-03 Operation VerifyCertificate - Fehler 4000" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_5449_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_04") echo "Executing test case "TIP1-A_5449-04 Operation VerifyCertificate - ablaufendes Zertifikat gegen Systemzeit" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_5449_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_05") echo "Executing test case "TIP1-A_5449-05 Operation VerifyCertificate - ablaufendes Zertifikat gegen Systemzeit" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_5449_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4701_02") echo "Executing test case "TIP1-A_4701-02 TUC_KON_035 Zertifikatsdienst initialisieren \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_01_Anwendungskonnektor/04_01_03_Zertifikatsdienst/04_01_03_01_Zertifikatsdienst/TIP1_A_4701_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3829_01") echo "Executing test case "GS-A_3829-01 Konnektor  Nutzung externer Namensraeume" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3829_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3829_02") echo "Executing test case "GS-A_3829-02 Resource Records des VPN-Zugangsdienstes TI \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3829_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3829_03") echo "Executing test case "GS-A_3829-03 Resource Records des VPN-Zugangsdienstes SIS \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3829_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3833_01") echo "Executing test case "GS-A_3833-01 DNSSEC-Protokoll  Resolver-Implementierungen" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3833_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3833_02") echo "Executing test case "GS-A_3833-02 DNSSEC-Protokoll  Resolver-Implementierungen Herstellererklärung \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3833_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3840_01") echo "Executing test case "GS-A_3840-01 RFC4035 - Recursive Name Servers" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3840_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3932_01") echo "Executing test case "GS-A_3932-01 Abfrage der in der Topologie am naechsten stehenden Nameservers" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3932_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3935_01") echo "Executing test case "GS-A_3935-01 NTP-Server-Implementierungen  Kiss-of-Death" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3935_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3936_01") echo "Executing test case "GS-A_3936-01 NTP-Server-Implementierungen  IBURST \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3936_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3938_01") echo "Executing test case "GS-A_3938-01 NTP-Server-Implementierungen  Association Mode und Polling Intervall" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3938_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3939_01") echo "Executing test case "GS-A_3939-01 Zeitsynchronisierung nach Neustart" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3939_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3942_01") echo "Executing test case "GS-A_3942-01 Produkttyp Konnektor  Stratum 3" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3942_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3945_01") echo "Executing test case "GS-A_3945-01 NTP-Server-Implementierungen  SNTP" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_3945_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4037_01") echo "Executing test case "GS-A_4037-01 DiffServ-Klassifizierung durch den Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4037_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4042_01") echo "Executing test case "GS-A_4042-01 DSCP-Markierung durch Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4042_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4048_01") echo "Executing test case "GS-A_4048-01 Priorisierung gemäss DSCP-Markierung \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4048_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4052_01") echo "Executing test case "GS-A_4052-01 Stateful Inspection" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4052_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4052_02") echo "Executing test case "GS-A_4052-02 Stateful Inspection" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4052_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4053_01") echo "Executing test case "GS-A_4053-01 Ingress und Egress Filtering" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4053_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4053_02") echo "Executing test case "GS-A_4053-02 Ingress und Egress Filtering" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4053_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4054_01") echo "Executing test case "GS-A_4054-01 Paketfilter Default Deny \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4054_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_01") echo "Executing test case "GS-A_4069-01 Erlaubter Verkehr Produkttypen" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_02") echo "Executing test case "GS-A_4069-02 NET_TI_GESICHERTE_FD - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_03") echo "Executing test case "GS-A_4069-03 NET_TI_ZENTRAL - zulaessige Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_04") echo "Executing test case "GS-A_4069-04 NET_TI_ZENTRAL - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_05") echo "Executing test case "GS-A_4069-05 NET_TI_ZENTRAL - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_06") echo "Executing test case "GS-A_4069-06 NET_TI_ZENTRAL - Kommunikation ohne VPN_TI" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_07") echo "Executing test case "GS-A_4069-07 NET_TI_DEZENTRAL - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_08") echo "Executing test case "GS-A_4069-08 ANLW_AKTIVE_BESTANDSNETZE - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_09") echo "Executing test case "GS-A_4069-09 ANLW_AKTIVE_BESTANDSNETZE  - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_10") echo "Executing test case "GS-A_4069-10 NET_SIS - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_11") echo "Executing test case "GS-A_4069-11 Internet \(via SIS\) - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_12") echo "Executing test case "GS-A_4069-12 Internet \(via SIS\) - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_13") echo "Executing test case "GS-A_4069-13 Internet \(via IAG\) - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_14") echo "Executing test case "GS-A_4069-14 Internet \(via IAG\) - Eingehende Kommunikation" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_15") echo "Executing test case "GS-A_4069-15 Kommunikation mit -Aktive Komponenten-" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_16") echo "Executing test case "GS-A_4069-16 Route zum IAG - zum WAN-Adapter eingehend" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_17") echo "Executing test case "GS-A_4069-17 Route zum IAG - zum LAN-Adapter eingehend" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_17.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_18") echo "Executing test case "GS-A_4069-18 Kommunikation mit dem Intranet - ANLW_INTRANET_ROUTES_MODUS= BLOCK" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_18.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_19") echo "Executing test case "GS-A_4069-19 Kommunikation mit dem Intranet- ANLW_INTRANET_ROUTES_MODUS= REDIRECT" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_19.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_20") echo "Executing test case "GS-A_4069-20 Kommunikation mit den Fachmodulen" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_20.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4069_21") echo "Executing test case "GS-A_4069-21 NET_SIS - Kommunikation von -Aktive Komponenten" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4069_21.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4075_01") echo "Executing test case "GS-A_4075-01 Produkttyp Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4075_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4070_01") echo "Executing test case "GS-A_4070-01 Widersprüchliche Spezifikationen" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4070_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_4075_01") echo "Executing test case "GS-A_4075-01" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4075_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4765_01") echo "Executing test case "GS-A_4765-01 DSCP-Markierung unverändert" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4765_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4766_01") echo "Executing test case "GS-A_4766-01 Regeldefinition zur Dienstklassifizierung \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4766_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4773_01") echo "Executing test case "GS-A_4773-01 Priorisierung gemäss DSCP-Markierung \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4773_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4772_01") echo "Executing test case "GS-A_4772-01 Bandbreitenbegrenzung durch Konnektor \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4772_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4774_01") echo "Executing test case "GS-A_4774-01 Klassenbasiertes Queuing im Konnektor \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4774_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4811_01") echo "Executing test case "GS-A_4811-01 Produkttyp Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4811_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4816_01") echo "Executing test case "GS-A_4816-01 Produkttyp Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4816_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4832_01") echo "Executing test case "GS-A_4832-01 Widersprüchliche Spezifikationen" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4832_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_01") echo "Executing test case "GS-A_4837-01 TSL-Download \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4848_01") echo "Executing test case "GS-A_4848-01 Produkttyp Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4848_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4849_01") echo "Executing test case "GS-A_4849-01 Produkttyp Konnektor" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4849_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4884_01") echo "Executing test case "GS-A_4884-01 Erlaubte ICMP-Types" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4884_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4891_01") echo "Executing test case "GS-A_4891-01 Testfallspezifikation noch nicht möglich" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4891_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5199_01") echo "Executing test case "GS-A_5199-01 DNSSEC im Namensraum Internet" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_5199_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_02") echo "Executing test case "GS-A_4837-02 KSR-Update und KSR-List_Updates \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_03") echo "Executing test case "GS-A_4837-03 VSD" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_04") echo "Executing test case "GS-A_4837-04 NTP \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_05") echo "Executing test case "GS-A_4837-05 DNS \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_06") echo "Executing test case "GS-A_4837-06 OCSP \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4837_07") echo "Executing test case "GS-A_4837-07 SNK \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_01_Uebergreifende_Spezifikation/04_02_01_01_Spezifikation_Netzwerk/GS_A_4837_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4787_01") echo "Executing test case "TIP1-A_4787-01  - - Konfigurationsabhängige Funktionsweise" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4787_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4788_01") echo "Executing test case "TIP1-A_4788-01  - - Verhalten bei Abweichung zwischen lokaler Zeit und erhaltenen Zeit" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4788_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4788_02") echo "Executing test case "TIP1-A_4788-02  - - Verhalten bei Abweichung zwischen lokaler Zeit und erhaltenen Zeit - Bootup" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4788_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4788_03") echo "Executing test case "TIP1-A_4788-03  - - Verhalten bei Abweichung zwischen lokaler Zeit und erhaltenen Zeit kleiner 1 Stunde" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4788_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4789_01") echo "Executing test case "TIP1-A_4789-01  - - Zustandsvariablen des Konnektor Zeitdiensts NTP_MAX_TIMEDIFFERENCE \(1\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4789_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4789_02") echo "Executing test case "TIP1-A_4789-02  - - Zustandsvariablen des Konnektor Zeitdiensts NTP_MAX_TIMEDIFFERENCE \(2\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4789_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4789_03") echo "Executing test case "TIP1-A_4789-03 Zustandsvariablen nicht vom Administrator aenderbar \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4789_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4790_01") echo "Executing test case "TIP1-A_4790-01  - - TUC_KON_351 Liefere Systemzeit \(Online-Betrieb\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4790_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4790_02") echo "Executing test case "TIP1-A_4790-02  - - TUC_KON_351 Liefere Systemzeit \(Offline-Betrieb\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4790_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4791_01") echo "Executing test case "TIP1-A_4791-01  - - Operation sync_Time \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4791_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4791_02") echo "Executing test case "TIP1-A_4791-02  - - Operation sync_Time \(Schlechtfall -MGM_LU_ONLINE = Disabled\) \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4791_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4791_03") echo "Executing test case "TIP1-A_4791-03  - - Operation sync_Time \(Schlechtfall -MGM_LOGICAL_SEPARATION = Enabled\) \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4791_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4792_01") echo "Executing test case "TIP1-A_4792-01  - - Explizites Anstossen der Zeitsynchronisierung \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4792_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4793_01") echo "Executing test case "TIP1-A_4793-01  - - Konfigurierbarkeit des Konnektor NTP-Servers - NTP_TIMEZONE \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4793_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4793_03") echo "Executing test case "TIP1-A_4793-03  - - Konfigurierbarkeit des Konnektor NTP-Servers - NTP_SERVER_ADDR" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4793_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4793_02") echo "Executing test case "TIP1-A_4793-02  - - Konfigurierbarkeit des Konnektor NTP-Servers - NTP_TIME \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4793_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4794_01") echo "Executing test case "TIP1-A_4794-01  - - Warnung und Übergang in kritischen Betriebszustand bei nichterfolgter Zeitsync." ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4794_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4795_01") echo "Executing test case "TIP1-A_4795-01  - - TUC_KON_352 Initialisierung Zeitdienst \(interaktiv\)" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4795_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4795_02") echo "Executing test case "TIP1-A_4795-02  - - TUC_KON_352 Initialisierung Zeitdienst - ANLW_SERVICE_TIMEOUT" ..."
		TestFaelle/04_Paket4/04_02_Netzkonnektor/04_02_02_Zeitdienst/04_02_02_01_Zeitdienst/TIP1_A_4795_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3695_01") echo "Executing test case "GS-A_3695-01 Grundlegender Aufbau Versionsnummern \(Selbstauskunft\) \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3695_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3696_01") echo "Executing test case "GS-A_3696-01 Zeitpunkt der Erzeugung neuer Versionsnummern \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3696_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3700_01") echo "Executing test case "GS-A_3700-01 Versionierung von Produkten auf Basis von dezentralen Produkttypen der ... \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3700_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3702_01") echo "Executing test case "GS-A_3702-01 Inhalt der Selbstauskunft von Produkten ausser Karten \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3702_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3796_01") echo "Executing test case "GS-A_3796-01 Transport Fehlermeldungen als gematik-SOAP-Fault" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3796_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3801_01") echo "Executing test case "GS-A_3801-01 Abbildung von Fehlern auf Transportprotokollebene" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3801_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3804_01") echo "Executing test case "GS-A_3804-01 Eigenschaften eines FehlerLog-Eintrags" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3804_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3804_02") echo "Executing test case "GS-A_3804-02 Eigenschaften eines FehlerLog-Eintrags \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3804_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3805_01") echo "Executing test case "GS-A_3805-01 Loglevel zur Bezeichnung der Granularitaet FehlerLog \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3805_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3807_01") echo "Executing test case "GS-A_3807-01 Fehlerspeicherung ereignisgesteuerter Nachrichtenverarbeitung" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3807_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3807_02") echo "Executing test case "GS-A_3807-02 Fehlerspeicherung bei Ereignissen des Kartenterminaldienstes und des Kartendienstes" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3807_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3807_03") echo "Executing test case "GS-A_3807-03 Fehlerspeicherung bei Ereignissen des DHCP-Clients" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3807_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3807_04") echo "Executing test case "GS-A_3807-04 Fehlerspeicherung bei Ereignissen des VPN-Clients" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3807_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3816_01") echo "Executing test case "GS-A_3816-01 Festlegung sicherheitsrelevanter Fehler" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3816_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3834_01") echo "Executing test case "GS-A_3834-01 DNS-Protokoll, Nameserver-Implementierung \(interaktiv\) " ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3834_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3931_01") echo "Executing test case "GS-A_3931-01 Betriebsdokumentation der dezentralen Produkte der TI-Platform \(interaktiv\) " ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3931_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3933_01") echo "Executing test case "GS-A_3933-01 NTP-Server-Implementierungen, Protokoll NTP4 \(interaktiv\) " ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3933_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3934_01") echo "Executing test case "GS-A_3934-01 Betriebsdokumentation der dezentralen Produkte der TI-Platform \(interaktiv\) " ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3934_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4349_01") echo "Executing test case "TIP1-A_4349-01 VPN-Zugangsdienst und Konnektor, IPsec-Protokoll \(interaktiv\) " ..."
		TestFaelle/03_Paket3/03_04_Spezifikation_VPN-Zugangsdienst/03_04_01_Spezifikation_VPN-Zugangsdienst/TIP1_A_4349_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_3856_01") echo "Executing test case "GS-A_3856-01 Struktur der Fehlermeldungen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_3856_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_01") echo "Executing test case "GS-A_4547-01 Generische Fehlermeldungen -Code 2-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_02") echo "Executing test case "GS-A_4547-02 Generische Fehlermeldungen -Code 3-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_03") echo "Executing test case "GS-A_4547-03 Generische Fehlermeldungen -Code 4-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_04") echo "Executing test case "GS-A_4547-04 Generische Fehlermeldungen -Code 6-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_05") echo "Executing test case "GS-A_4547-05 Generische Fehlermeldungen -Code 101-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_06") echo "Executing test case "GS-A_4547-06 Generische Fehlermeldungen -Code 105-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_07") echo "Executing test case "GS-A_4547-07 Generische Fehlermeldungen -Code 106-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_08") echo "Executing test case "GS-A_4547-08 Generische Fehlermeldungen -Code 107-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_09") echo "Executing test case "GS-A_4547-09 Generische Fehlermeldungen -Code 108-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_10") echo "Executing test case "GS-A_4547-10 Generische Fehlermeldungen -Code 112-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_11") echo "Executing test case "GS-A_4547-11 Generische Fehlermeldungen -Code 113-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4547_12") echo "Executing test case "GS-A_4547-12 Generische Fehlermeldungen -Code 114-" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4547_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4858_01") echo "Executing test case "GS-A_4858-01 Nutzung von Herstellerspezifischen Errorcodes \(Konnektor\) \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4858_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4864_01") echo "Executing test case "GS-A_4864-01 Logging-Vorgaben nach dem Uebergang zum Wirkbetrieb \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4864_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4865_01") echo "Executing test case "GS-A_4865-01 Versionierte Liste zulaessiger Firmware-Versionen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4865_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4867_01") echo "Executing test case "GS-A_4867-01 Uebernahme Firmware-Gruppe manuell \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4867_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4867_02") echo "Executing test case "GS-A_4867-02 Uebernahme Firmware-Gruppe automatisch \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4867_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4867_03") echo "Executing test case "GS-A_4867-03 Uebernahme Firmware-Gruppe \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4867_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4868_01") echo "Executing test case "GS-A_4868-01 Aufsteigende Nummerierung der Firmware-Gruppen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4868_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4869_01") echo "Executing test case "GS-A_4869-01 Firmware-Gruppe mindestens eine Firmware-Version" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4869_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4869_02") echo "Executing test case "GS-A_4869-02 Firmware-Gruppe enthhält nur eine Firmware-Version" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4869_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4870_01") echo "Executing test case "GS-A_4870-01 Wechsel zu jeder Firmware-Version der aktuellen Firmware-Gruppe \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4870_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4871_01") echo "Executing test case "GS-A_4871-01 Upgrade nur auf hoehere Firmware-Gruppen-Version \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4871_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4872_01") echo "Executing test case "GS-A_4872-01 Kein Downgrade der Firmware-Gruppe \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4872_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4941_01") echo "Executing test case "GS-A_4941-01 Betriebsdokumentation der dezentralen Produkte der TI-Plattform \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4941_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5034_01") echo "Executing test case "GS-A_5034-01 Inhalte der Betriebsdokumentation \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_5034_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5038_01") echo "Executing test case "GS-A_5038-01 Festlegungen zur Vergabe einer Produktversion \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_5038_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5038_02") echo "Executing test case "GS-A_5038-02 Festlegungen zur Vergabe einer Produktversion \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_5038_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5325_01") echo "Executing test case "GS-A_5325-01 Performance-Konnektor-Kapazitätsplanung \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_5325_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4867_04") echo "Executing test case "GS-A_4867-04 Uebernahme Firmware-Gruppe obwohl Integrität nok \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_01_Operations_and_Maintenance/GS_A_4867_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4386_01") echo "Executing test case "GS-A_4386-01 TLS-Verbindungen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_02_Verwendung_kryptographischer_Algorithmen_in_der_TI/GS_A_4386_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4388_01") echo "Executing test case "GS-A_4388-01 DNSSEC-Kontext" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_02_Verwendung_kryptographischer_Algorithmen_in_der_TI/GS_A_4388_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5080_01") echo "Executing test case "GS-A_5080-01 Signaturen binärer Daten \(Dokumente\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_02_Verwendung_kryptographischer_Algorithmen_in_der_TI/GS_A_5080_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5081_01") echo "Executing test case "GS-A_5081-01 Signaturen von PDF-A-Dokumenten" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_02_Verwendung_kryptographischer_Algorithmen_in_der_TI/GS_A_5081_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5091_01") echo "Executing test case "GS-A_5091-01 Verwendung von RSASSA-PSS bei XMLDSig-Signaturen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_02_Verwendung_kryptographischer_Algorithmen_in_der_TI/GS_A_5091_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4637_01") echo "Executing test case "GS-A_4637-01 TUCs" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4637_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4642_01") echo "Executing test case "GS-A_4642-01 TUC_PKI_001 - Periodische Aktualisierung TI-Vertrauensraum" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4642_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4643_01") echo "Executing test case "GS-A_4643-01 TUC_PKI_013 - Import TI-Vertrauensanker aus TSL" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4643_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4646_01") echo "Executing test case "GS-A_4646-01 TUC_PKI_017 - Lokalisierung TSL Download-Adressen" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4646_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4647_01") echo "Executing test case "GS-A_4647-01 TUC_PKI_016 - Download der TSL-Datei - OK" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4647_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4648_01") echo "Executing test case "GS-A_4648-01 TUC_PKI_019 - Prüfung der Aktualität der TSL" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4648_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4649_01") echo "Executing test case "GS-A_4649-01 TUC_PKI_020 - XML-Dokument validieren" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4649_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4650_01") echo "Executing test case "GS-A_4650-01 TUC_PKI_011 - Prüfung des TSL-Signer-Zertifikates" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4650_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4651_01") echo "Executing test case "GS-A_4651-01 TUC_PKI_012 - XML-Signatur-Prüfung" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4651_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4652_01") echo "Executing test case "GS-A_4652-01 TUC_PKI_018 - Zertifikatsprüfung in der TI" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4652_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4653_01") echo "Executing test case "GS-A_4653-01 TUC_PKI_002 - Gültigkeitsprüfung des Zertifikats" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4653_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4654_01") echo "Executing test case "GS-A_4654-01 TUC_PKI_003 - CA-Zertifikat finden" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4654_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4655_01") echo "Executing test case "GS-A_4655-01 TUC_PKI_004 - Mathematische Prüfung der Zertifikatssignatur" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4655_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4656_01") echo "Executing test case "GS-A_4656-01 TUC_PKI_005 - Adresse für Status- und Sperrprüfung ermitteln - OCSP \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4656_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4656_02") echo "Executing test case "GS-A_4656-02 TUC_PKI_005 - Adresse für Status- und Sperrprüfung ermitteln - CRL" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4656_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4657_01") echo "Executing test case "GS-A_4657-01 TUC_PKI_006 - OCSP-Abfrage \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4657_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4658_01") echo "Executing test case "GS-A_4658-01 Zertifikatsprüfung in spezifizierten Offline-Szenarien" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4658_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4659_01") echo "Executing test case "GS-A_4659-01 Zertifikatsprüfung bei Nichterreichbarkeit des OCSP" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4659_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4660_01") echo "Executing test case "GS-A_4660-01 TUC_PKI_009 - Rollenermittlung" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4660_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4661_01") echo "Executing test case "GS-A_4661-01 kritische Erweiterungen in Zertifikaten" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4661_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4662_01") echo "Executing test case "GS-A_4662-01 Bedingungen fuer TLS-Handshake" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4662_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4662_02") echo "Executing test case "GS-A_4662-02 Fehlerhaftes Zertifikat" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4662_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4662_03") echo "Executing test case "GS-A_4662-03 TLS-Handshake nicht erfolgreich" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4662_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_4662_04") echo "Executing test case "GS-A_4662-04 TLS-Handshake nicht erfolgreich" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4662_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4663_01") echo "Executing test case "GS-A_4663-01 Zertifikats-Prüfparameter für den TLS-Aufbau" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4663_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4663_02") echo "Executing test case "GS-A_4663-02 Zertifikats-Prüfparameter für den TLS-Aufbau - Grace Period" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4663_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4749_01") echo "Executing test case "GS-A_4749-01 TUC_PKI_007 - Prüfung Zertifikatstyp" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4749_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_01") echo "Executing test case "GS-A_4751-01 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1001" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_02") echo "Executing test case "GS-A_4751-02 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1002 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_03") echo "Executing test case "GS-A_4751-03 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1003 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_04") echo "Executing test case "GS-A_4751-04 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1004 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_05") echo "Executing test case "GS-A_4751-05 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1005 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_06") echo "Executing test case "GS-A_4751-06 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1006 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_07") echo "Executing test case "GS-A_4751-07 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1007 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_08") echo "Executing test case "GS-A_4751-08 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1008 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_09") echo "Executing test case "GS-A_4751-09 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1009 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_10") echo "Executing test case "GS-A_4751-10 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1011 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_11") echo "Executing test case "GS-A_4751-11 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1012 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_12") echo "Executing test case "GS-A_4751-12 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1013 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_13") echo "Executing test case "GS-A_4751-13 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1016" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_14") echo "Executing test case "GS-A_4751-14 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1017 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_15") echo "Executing test case "GS-A_4751-15 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1019" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_16") echo "Executing test case "GS-A_4751-16 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1021" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_17") echo "Executing test case "GS-A_4751-17 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1023" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_17.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_18") echo "Executing test case "GS-A_4751-18 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1024" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_18.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_19") echo "Executing test case "GS-A_4751-19 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1026 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_19.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_20") echo "Executing test case "GS-A_4751-20 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1027" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_20.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_21") echo "Executing test case "GS-A_4751-21 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1028 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_21.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_22") echo "Executing test case "GS-A_4751-22 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1030 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_22.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_23") echo "Executing test case "GS-A_4751-23 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1031" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_23.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_24") echo "Executing test case "GS-A_4751-24 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1033" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_24.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_25") echo "Executing test case "GS-A_4751-25 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1036 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_25.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_26") echo "Executing test case "GS-A_4751-26 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1042 \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_26.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_27") echo "Executing test case "GS-A_4751-27 - OBSOLET" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_27.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_28") echo "Executing test case "GS-A_4751-28 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1044" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_28.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_29") echo "Executing test case "GS-A_4751-29 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1047" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_29.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_30") echo "Executing test case "GS-A_4751-30 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1053" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_30.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_31") echo "Executing test case "GS-A_4751-31 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1054" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_31.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_32") echo "Executing test case "GS-A_4751-32 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1055" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_32.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_33") echo "Executing test case "GS-A_4751-33 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1057" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_33.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4751_34") echo "Executing test case "GS-A_4751-34 Fehlercodes bei TSL- und Zertifikatsprüfung - Fehler 1058" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4751_34.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4829_01") echo "Executing test case "GS-A_4829-01 TUCs" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4829_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4957_01") echo "Executing test case "GS-A_4957-01 Beschraenkungen OCSP-Request" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4957_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4898_01") echo "Executing test case "GS-A_4898-01 TSL-Grace-Period einer TSL \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4898_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4899_01") echo "Executing test case "GS-A_4899-01 TSL Update-Prüfintervall" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4899_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4900_01") echo "Executing test case "GS-A_4900-01 TUC_PKI_021 - CRL-Prüfung" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4900_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4957_01") echo "Executing test case "GS-A_4957-01 Beschraenkungen OCSP-Request" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4957_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5077_01") echo "Executing test case "GS-A_5077-01 FQDN-Prüfung beim TLS-Aufbau" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5077_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5077_02") echo "Executing test case "GS-A_5077-02 FQDN in Zertifikat stimmt nicht mit FQDN der Komponente ueberein" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5077_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5078_01") echo "Executing test case "GS-A_5078-01 FQDN-Prüfung beim IPsec-Aufbau" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5078_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5078_02") echo "Executing test case "GS-A_5078-02 Fehlgeschlagene FQDN-Prüfung beim IPsec-Aufbau" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5078_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5215_01") echo "Executing test case "GS-A_5215-01 OCSP-Response mit nextUpdate in Vergangenheit innerhalb Toleranz" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5215_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5215_02") echo "Executing test case "GS-A_5215-02 OCSP-Response mit nextUpdate in Vergangenheit ausserhalb Toleranz" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5215_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5215_03") echo "Executing test case "GS-A_5215-03 OCSP-Response mit thisUpdate in Zukunft innerhalb Toleranz" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5215_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5215_04") echo "Executing test case "GS-A_5215-04 OCSP-Response mit thisUpdate in Zukunft ausserhalb Toleranz" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5215_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4648_02") echo "Executing test case "GS-A_4648-02 TSL-Grace-Period einer TSL \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4648_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4648_03") echo "Executing test case "GS-A_4648-03 Konfigurierbarkeit des Zertifikatsdienstes \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4648_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_4749_02") echo "Executing test case "GS-A_4749-02 TUC_PKI_007 - Prüfung Zertifikatstyp CERT_TYPE_MISMATCH" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_4749_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5077_03") echo "Executing test case "GS-A_5077-03 FQDN-Prüfung beim TLS-Aufbau zu Fachdienst" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5077_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5077_04") echo "Executing test case "GS-A_5077-04 FQDN-Prüfung beim TLS-Aufbau zu Fachdienst \(Fehler\)" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/GS_A_5077_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5120_01") echo "Executing test case "TIP1-A_5120-01 Clients des TSL-Dienstes - HTTP-Komprimierung unterstützen" ..."
		TestFaelle/05_Paket5/05_02_Spezifikation_TSL-Dienst/05_02_01_Spezifikation_TSL_Dienst/TIP1_A_5120_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4723_01") echo "Executing test case "TIP1-A_4723-01 Routing LAN - Internet via SIS" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4723_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4723_02") echo "Executing test case "TIP1-A_4723-02 Routing LAN - Aktive Bestandsnetze" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4723_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4723_03") echo "Executing test case "TIP1-A_4723-03 MTU fuer LAN-Schnittstelle konfigurierbar" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4723_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4723_04") echo "Executing test case "TIP1-A_4723-04 MTU fuer WAN-Schnittstelle konfigurierbar" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4723_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4725_01") echo "Executing test case "TIP1-A_4725-01 WAN-Adapter" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4725_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4729_01") echo "Executing test case "TIP1-A_4729-01 Es darf kein dynamisches Routing verwendet werden" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4729_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4730_01") echo "Executing test case "TIP1-A_4730-01 NET_TI_GESICHERTE_FD - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4730_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4730_02") echo "Executing test case "TIP1-A_4730-02 NET_TI_GESICHERTE_FD - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4730_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4731_01") echo "Executing test case "TIP1-A_4731-01 NET_TI_ZENTRAL - zulaessige Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4731_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4731_02") echo "Executing test case "TIP1-A_4731-02 NET_TI_ZENTRAL - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4731_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4731_03") echo "Executing test case "TIP1-A_4731-03 NET_TI_ZENTRAL - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4731_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4731_04") echo "Executing test case "TIP1-A_4731-04 obsolet" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4731_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4732_01") echo "Executing test case "TIP1-A_4732-01 NET_TI_DEZENTRAL - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4732_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4733_01") echo "Executing test case "TIP1-A_4733-01  - - ANLW_AKTIVE_BESTANDSNETZE - Kommunikation von Aktive Komponenten blockieren" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4733_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4733_02") echo "Executing test case "TIP1-A_4733-02  - - ANLW_AKTIVE_BESTANDSNETZE - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4733_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4733_03") echo "Executing test case "TIP1-A_4733-03  - - ANLW_AKTIVE_BESTANDSNETZE - unterstützte Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4733_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4734_01") echo "Executing test case "TIP1-A_4734-01 NET_SIS - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4734_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4734_02") echo "Executing test case "TIP1-A_4734-02 NET_SIS - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4734_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4735_01") echo "Executing test case "TIP1-A_4735-01 Internet \(via SIS\) - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4735_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4735_02") echo "Executing test case "TIP1-A_4735-02 Internet \(via SIS\) - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4735_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4735_03") echo "Executing test case "TIP1-A_4735-03 Internet \(via SIS\) - Erlaubte Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4735_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4736_01") echo "Executing test case "TIP1-A_4736-01 Internet \(via IAG\) - Kommunikation von Aktive Komponenten" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4736_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4736_02") echo "Executing test case "TIP1-A_4736-02 Internet \(via IAG\) - Eingehende Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4736_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4736_03") echo "Executing test case "TIP1-A_4736-03 Internet \(via IAG\) - Erlaubte Kommunikation VPN-TI-Konzentrator" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4736_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4736_04") echo "Executing test case "TIP1-A_4736-04 Internet \(via IAG\) - Erlaubte Kommunikation VPN-SIS-Konzentrator" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4736_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4737_01") echo "Executing test case "TIP1-A_4737-01 Kommunikation mit -Aktive Komponenten-" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4737_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4738_01") echo "Executing test case "TIP1-A_4738-01 Route zum IAG - zum WAN-Adapter eingehend" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4738_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4738_02") echo "Executing test case "TIP1-A_4738-02 Route zum IAG - zum LAN-Adapter eingehend" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4738_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4740_01") echo "Executing test case "TIP1-A_4740-01 Admin Defined Firewall Rules" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4740_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4741_01") echo "Executing test case "TIP1-A_4741-01 Kommunikation mit dem Intranet - ANLW_INTRANET_ROUTES_MODUS= BLOCK" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4741_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4741_02") echo "Executing test case "TIP1-A_4741-02 Kommunikation mit dem Intranet- ANLW_INTRANET_ROUTES_MODUS= REDIRECT" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4741_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4741_04") echo "Executing test case "TIP1-A_4741-04 Kommunikation mit dem Intranet - vom Konnektor kommend" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4741_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	

	"TIP1_A_4742_01") echo "Executing test case "TIP1-A_4742-01 Kommunikation mit den Fachmodulen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4742_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4744_01") echo "Executing test case "TIP1-A_4744-01 Firewall -Drop statt Reject" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4744_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4745_01") echo "Executing test case \"TIP1-A_4745-01  - - TCP-Port-7 (Echo)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4745_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4746_01") echo "Executing test case \"TIP1-A_4746-01  - - Firewall - Abwehr von IP-Spoofing  DoS_DDoS-Angriffe und Martian Packets\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4746_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4763_01") echo "Executing test case \"TIP1-A_4763-01  - - DHCP-Server des Konnektors (interaktiv)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4763_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4763_02") echo "Executing test case \"TIP1-A_4763-02  - - DHCP-Server des Konnektors\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4763_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4763_03") echo "Executing test case \"TIP1-A_4763-03  - - DHCP-Server des Konnektors\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4763_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_01") echo "Executing test case \"TIP1-A_4765-01  - - Liefere Netzwerkinformationen über DHCP\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_02") echo "Executing test case \"TIP1-A_4765-02  - - Liefere Netzwerkinformationen ueber DHCP (DHCP-Server disabled)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_03") echo "Executing test case \"TIP1-A_4765-03  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_OWNDNS_ENABLED)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_04") echo "Executing test case \"TIP1-A_4765-04  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_NTP)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_05") echo "Executing test case \"TIP1-A_4765-05  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_OWNDGW_ENABLED)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_06") echo "Executing test case \"TIP1-A_4765-06  - - Liefere Netzwerkinformationen ueber DHCP (DHCP_IP_RANGE)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_07") echo "Executing test case \"TIP1-A_4765-07  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_DOMAINNAME)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_08") echo "Executing test case \"TIP1-A_4765-08  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_HOSTNAME)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_09") echo "Executing test case \"TIP1-A_4765-09  - - Liefere Netzwerkinformationen ueber DHCP (Parameter-Variante DHCP_LEASE_TTL)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_10") echo "Executing test case \"TIP1-A_4765-10  - - obsolet\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4765_11") echo "Executing test case \"TIP1-A_4765-11  - - Liefere Netzwerkinformationen ueber DHCP (DHCP_IP_RANGE)\" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4765_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4766_01") echo "Executing test case "TIP1-A_4766-01  - - Deaktivierbarkeit des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4766_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4766_02") echo "Executing test case "TIP1-A_4766-02  - - Deaktivierbarkeit des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4766_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_01") echo "Executing test case "TIP1-A_4767-01  - - Konfiguration des DHCP-Servers DHCP_SERVER_NETWORK \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_02") echo "Executing test case "TIP1-A_4767-02  - - obsolet" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_03") echo "Executing test case "TIP1-A_4767-03  - - Konfiguration des DHCP-Servers DHCP_SERVER_BROADCAST \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_04") echo "Executing test case "TIP1-A_4767-04  - - obsolet" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_05") echo "Executing test case "TIP1-A_4767-05  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_06") echo "Executing test case "TIP1-A_4767-06  - - Konfiguration des DHCP-Servers DHCP_SERVER_DYNAMIC_RANGE \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_07") echo "Executing test case "TIP1-A_4767-07  - - Konfiguration des DHCP-Servers DHCP_SERVER_DEFAULT_CLIENTGROUP \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_08") echo "Executing test case "TIP1-A_4767-08  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_09") echo "Executing test case "TIP1-A_4767-09  - - obsolet" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_10") echo "Executing test case "TIP1-A_4767-10  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_11") echo "Executing test case "TIP1-A_4767-11  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_11.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_12") echo "Executing test case "TIP1-A_4767-12  - - obsolet" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_12.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_13") echo "Executing test case "TIP1-A_4767-13  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_13.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_14") echo "Executing test case "TIP1-A_4767-14  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_14.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_15") echo "Executing test case "TIP1-A_4767-15  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_15.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4767_16") echo "Executing test case "TIP1-A_4767-16  - - Konfiguration des DHCP-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4767_16.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4768_01") echo "Executing test case "TIP1-A_4768-01  - - TUC_KON_343 Initialisierung DHCP-Server" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_01_DHCP_Server/TIP1_A_4768_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4769_01") echo "Executing test case "TIP1-A_4769-01  - - DHCP Client Funktionalität des Konnektors \(LAN-seitig\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4769_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4769_02") echo "Executing test case "TIP1-A_4769-02  - - DHCP Client Funktionalität des Konnektors \(WAN-seitig\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4769_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4769_03") echo "Executing test case "TIP1-A_4769-03  - - DHCP Client Funktionalität des Konnektors \(LAN-seitig" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4769_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4769_04") echo "Executing test case "TIP1-A_4769-04  - - DHCP Client Funktionalität des Konnektors \(WAN-seitig" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4769_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4769_05") echo "Executing test case "TIP1-A_4769-05  - - DHCP Client Funktionalität des Konnektors \(Konnektor DHCP-Server enabled\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4769_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4771_01") echo "Executing test case "TIP1-A_4771-01  - - Reagieren auf DHCP-Client-StateChanged-Ereignisse \(DHCP-LAN_CLIENT-STATECHANGED\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4771_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4771_02") echo "Executing test case "TIP1-A_4771-02  - - Reagieren auf DHCP-Client-StateChanged-Ereignisse \(DHCP-WAN_CLIENT-STATECHANGED\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4771_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_01") echo "Executing test case "TIP1-A_4772-01  - - TUC_KON_341 DHCP-Informationen beziehen - Bootup - LAN-seitig \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_02") echo "Executing test case "TIP1-A_4772-02  - - TUC_KON_341 DHCP-Informationen beziehen - Bootup - WAN-seitig \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_03") echo "Executing test case "TIP1-A_4772-03  - - TUC_KON_341 DHCP-Informationen beziehen - Ablauf DHCP-Lease - LAN \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_04") echo "Executing test case "TIP1-A_4772-04  - - TUC_KON_341 DHCP-Informationen beziehen - Ablauf DHCP-Lease - WAN \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_05") echo "Executing test case "TIP1-A_4772-05  - - TUC_KON_341 DHCP-Informationen beziehen - identische IP Adressen\(1\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_06") echo "Executing test case "TIP1-A_4772-06  - - TUC_KON_341 DHCP-Informationen beziehen - identische IP Adressen\(2\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_07") echo "Executing test case "TIP1-A_4772-07  - - TUC_KON_341 DHCP-Informationen beziehen - LAN - Keine DHCP-Antwort" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_08") echo "Executing test case "TIP1-A_4772-08  - - TUC_KON_341 DHCP-Informationen beziehen - WAN - Keine DHCP-Antwort" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_09") echo "Executing test case "TIP1-A_4772-09  - - TUC_KON_341 DHCP-Informationen beziehen - Aufruf für LAN ohne Wirkung auf WAN \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4772_10") echo "Executing test case "TIP1-A_4772-10  - - TUC_KON_341 DHCP-Informationen beziehen - Aufruf für WAN ohne Wirkung auf LAN \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4772_10.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4773_01") echo "Executing test case "TIP1-A_4773-01  - - Konfiguration des DHCP-Clients \(LAN aktivieren\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4773_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4773_02") echo "Executing test case "TIP1-A_4773-02  - - Konfiguration des DHCP-Clients \(WAN aktivieren\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4773_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4773_03") echo "Executing test case "TIP1-A_4773-03  - - Konfiguration des DHCP-Clients \(LAN deaktivieren\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4773_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4773_04") echo "Executing test case "TIP1-A_4773-04  - - Konfiguration des DHCP-Clients \(WAN deaktivieren\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4773_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4774_01") echo "Executing test case "TIP1-A_4774-01  - - Manuelles anstossen eines DHCP-Lease-Renew \(LAN-seitig\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4774_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4774_02") echo "Executing test case "TIP1-A_4774-02  - - Manuelles anstossen eines DHCP-Lease-Renew \(WAN-seitig\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4774_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4775_01") echo "Executing test case "TIP1-A_4775-01  - - Aktive DHCP-Clients bei Auslieferung des Konnektors" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4775_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4776_01") echo "Executing test case "TIP1-A_4776-01  - - Setzen der IP-Adresse nach Timeout" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_02_DHCP/05_04_02_02_DHCP_Client/TIP1_A_4776_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_01") echo "Executing test case "TIP1-A_4796-01  - - Grundlagen des Namensdienstes - Recursive Caching Nameserver" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_02") echo "Executing test case "TIP1-A_4796-02  - - Grundlagen des Namensdienstes - Recursive Caching Nameserver - Rekursion" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_03") echo "Executing test case "TIP1-A_4796-03  - - Grundlagen des Namensdienstes - Zone Transfer" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_04") echo "Executing test case "TIP1-A_4796-04  - - Grundlagen des Namensdienstes - Anfragen WAN" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_05") echo "Executing test case "TIP1-A_4796-05  - - Grundlagen des Namensdienstes - CD Bit" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_06") echo "Executing test case "TIP1-A_4796-06  - - Grundlagen des Namensdienstes - ANLW_LEKTR_INTRANET_ROUTES" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_07") echo "Executing test case "TIP1-A_4796-07  - - Grundlagen des Namensdienstes - Validating Resolver" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4796_08") echo "Executing test case "TIP1-A_4796-08  - - Grundlagen des Namensdienstes - ANLW_SERVICE_TIMEOUT" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4796_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4797_01") echo "Executing test case "TIP1-A_4797-01  - - DNS-Forwards des DNS-Servers" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4797_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4797_02") echo "Executing test case "TIP1-A_4797-02  - - DNS-Forwards des DNS-Servers - Parameter MGM_LU_ONLINE = Disabled" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4797_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4797_03") echo "Executing test case "TIP1-A_4797-03  - - DNS-Forwards des DNS-Servers - Parameter MGM_LOGICAL_SEPARATION = Enabled" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4797_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4797_04") echo "Executing test case "TIP1-A_4797-04  - - DNS-Forwards des DNS-Servers - Parameter MGM_LOGICAL_SEPARATION = Enabled \(2\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4797_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4799_01") echo "Executing test case "TIP1-A_4799-01 Aktualitaet der DNS-Vertrauensanker sicherstellen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4799_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4801_01") echo "Executing test case "TIP1-A_4801-01  - - TUC_KON_361 DNS-Namen auflösen - DNS Fehler - 4180" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4801_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4801_02") echo "Executing test case "TIP1-A_4801-02  - - TUC_KON_361 DNS-Namen auflösen - DNS Timeout - 4179" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4801_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4801_03") echo "Executing test case "TIP1-A_4801-03  - - TUC_KON_361 DNS-Namen auflösen - Liste IP Adressen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4801_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4802_01") echo "Executing test case "TIP1-A_4802-01  - - TUC_KON_362 Liste der Dienste abrufen - DNS Fehler - 4180" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4802_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4802_02") echo "Executing test case "TIP1-A_4802-02  - - TUC_KON_362 Liste der Dienste abrufen - DNS Timeout - 4179" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4802_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4802_03") echo "Executing test case "TIP1-A_4802-03  - - TUC_KON_362 Liste der Dienste abrufen - PTR" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4802_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4803_01") echo "Executing test case "TIP1-A_4803-01  - - TUC_KON_363 Dienstdetails abrufen - DNS Fehler - 4180" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4803_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4803_02") echo "Executing test case "TIP1-A_4803-02  - - TUC_KON_363 Dienstdetails abrufen - DNS Timeout - 4179" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4803_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4803_03") echo "Executing test case "TIP1-A_4803-03  - - TUC_KON_363 Dienstdetails abrufen - DNS-SD" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4803_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4804_01") echo "Executing test case "TIP1-A_4804-01  - - Basisanwendung Namensdienst" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4804_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_01") echo "Executing test case "TIP1-A_4805-01  - - Konfigurationsparameter Namensdienst und Dienstlok. - DNS_SERVERS_INT \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_02") echo "Executing test case "TIP1-A_4805-02  - - Konfigurationsparameter Namensdienst und D. - DNS_DOMAIN_VPN_ZUGD_INT \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_03") echo "Executing test case "TIP1-A_4805-03  - - Konfigurationsparameter Namensdienst und D. - DNS_SERVERS_LEKTR \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_04") echo "Executing test case "TIP1-A_4805-04  - - Konfigurationsparameter Namensdienst und D. - DNS_DOMAIN_LEKTR \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_05") echo "Executing test case "TIP1-A_4805-05  - - Konfigurationsparameter Namensdienst und D. - DNS_ROOT_ANCHOR_URL \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_06") echo "Executing test case "TIP1-A_4805-06  - - Konfigurationsparameter Namensdienst und Dienstlok. - DNS_SERVERS_TI \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_07") echo "Executing test case "TIP1-A_4805-07  - - Konfigurationsparameter Namensdienst und Dienstlok. - DNS_SERVERS_SIS \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_08") echo "Executing test case "TIP1-A_4805-08  - - Konfigurationsparameter Namensdienst - DNS_SERVERS_BESTANDSNETZE \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4805_09") echo "Executing test case "TIP1-A_4805-09  - - Konfigurationsparameter Namensdienst - DNS_TOP_LEVEL_DOMAIN_TI \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_4805_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5035_01") echo "Executing test case "TIP1-A_5035-01  - - Operation GetIPAddress - Klärungsbedarf" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_5035_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5416_01") echo "Executing test case "TIP1-A_5416-01  - - Initialisierung Namensdienst und Dienstlokalisierung" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_03_Namensdienst_und_Dienstlokalisierung/05_04_03_01_Namensdienst_und_Dienstlokalisierung/TIP1_A_5416_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4778_01") echo "Executing test case "TIP1-A_4778-01 Anforderungen an den VPN-Client" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4778_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4778_02") echo "Executing test case "TIP1-A_4778-02 Anforderungen an den VPN-Client" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4778_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4778_03") echo "Executing test case "TIP1-A_4778-03 Anforderungen an den VPN-Client" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4778_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4778_04") echo "Executing test case "TIP1-A_4778-04 Anforderungen an den VPN-Client" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4778_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4779_01") echo "Executing test case "TIP1-A_4779-01  - - Wiederholte Fehler beim VPN-Verbindungsaufbau \(VPN_TI\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4779_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4779_02") echo "Executing test case "TIP1-A_4779-02  - - Wiederholte Fehler beim VPN-Verbindungsaufbau \(SIS_TI\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4779_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4780_01") echo "Executing test case "TIP1-A_4780-01  - - TI VPN-Client Start Events \(LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4780_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4780_02") echo "Executing test case "TIP1-A_4780-02  - - TI VPN-Client Start Events \(VPN_TI-DOWN\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4780_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4780_03") echo "Executing test case "TIP1-A_4780-03  - - TI VPN-Client Start Events \(LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4780_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_01") echo "Executing test case "TIP1-A_4781-01  - - SIS VPN-Client Start Events" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_02") echo "Executing test case "TIP1-A_4781-02  - - SIS VPN-Client Start Events \(VPN_SIS-DOWN\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_03") echo "Executing test case "TIP1-A_4781-03  - - SIS VPN-Client Start Events \(LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_04") echo "Executing test case "TIP1-A_4781-04  - - SIS VPN-Client Start Events \(VPN_TI nicht verfügbar\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_05") echo "Executing test case "TIP1-A_4781-05  - - SIS VPN-Client Start Events \(ANLW_INTERNET_MODUS=IAG\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4781_06") echo "Executing test case "TIP1-A_4781-06  - - SIS VPN-Client Start Events \(ANLW_INTERNET_MODUS=KEINER\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4781_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4782_01") echo "Executing test case "TIP1-A_4782-01 SIS VPN-Client Stop Events \(MGM_LOGICAL_SEPARATION\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4782_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4782_02") echo "Executing test case "TIP1-A_4782-02 SIS VPN-Client Stop Events \(MGM_LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4782_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_02") echo "Executing test case "TIP1-A_4783-02 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen \(MGM_LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_01") echo "Executing test case "TIP1-A_4783-01 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_03") echo "Executing test case "TIP1-A_4783-03 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen \(Abbau\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_04") echo "Executing test case "TIP1-A_4783-04 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen \(Bestehende Verb.\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_05") echo "Executing test case "TIP1-A_4783-05 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen \(Fehler 4174\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4783_06") echo "Executing test case "TIP1-A_4783-06 TUC_KON_321 Verbindung zu dem VPN-Konzentrator der TI aufbauen \(Fehler 4174\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4783_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_01") echo "Executing test case "TIP1-A_4784-01 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_02") echo "Executing test case "TIP1-A_4784-02 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(Abbau\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_02.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_03") echo "Executing test case "TIP1-A_4784-03 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(Bestehende Verb.\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_03.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_04") echo "Executing test case "TIP1-A_4784-04 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(MGM_LU_ONLINE\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_05") echo "Executing test case "TIP1-A_4784-05 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(MGM_LOGICAL_SEP.\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_05.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_06") echo "Executing test case "TIP1-A_4784-06 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(INTERNET_MODUS=IAG\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_06.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_07") echo "Executing test case "TIP1-A_4784-07 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(INT._MODUS=KEINER\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_07.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_08") echo "Executing test case "TIP1-A_4784-08 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(Fehler 4176\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_08.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4784_09") echo "Executing test case "TIP1-A_4784-09 TUC_KON_322 Verbindung zu dem VPN-Konzentrator des SIS aufbauen \(Fehler 4176\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4784_09.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4785_01") echo "Executing test case "TIP1-A_4785-01  - - Konfigurationsparameter je Zugangsdienst-Provider" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4785_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5415_01") echo "Executing test case "TIP1-A_5415-01 Initialisierung VPN-Client" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_5415_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5417_01") echo "Executing test case "TIP1-A_5417-01 TI VPN-Client Stop Events" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_5417_01.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4780_04") echo "Executing test case "TIP1-A_4780-04 Fachliche Nutzung des VPN-TI-Tunnels nach Aufbau" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_04_VPN-Client/05_04_04_01_VPN-Client/TIP1_A_4780_04.sh   2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4753_01") echo "Executing test case "TIP1-A_4753-01" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4753_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4753_02") echo "Executing test case "TIP1-A_4753-02" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4753_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4754_01") echo "Executing test case "TIP1-A_4754-01 TUC_KON_305 LAN-Adapter initialisieren nach manuellem DHCP-Renew" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4754_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt		
	;;
	
	"TIP1_A_4754_02") echo "Executing test case "TIP1-A_4754-02 TUC_KON_305 LAN-Adapter initialisieren - Fehlerhafte Konfiguration" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4754_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt		
	;;	
	
	"TIP1_A_4754_03") echo "Executing test case "TIP1-A_4754-03 Manuelle Konfiguration" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4754_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt		
	;;
	
	"TIP1_A_4754_01") echo "Executing test case "TIP1-A_4754-01 TUC_KON_305 LAN-Adapter initialisieren - Fehlerhafte Konfiguration" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4754_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt		
	;;
	
	"TIP1_A_4759_06") echo "Executing test case "TIP1-A_4759-06 Ueberlappung mit NET_TI_OFFENE_FD \(interaktiv\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4750_01") echo "Executing test case "TIP1-A_4750-01 Aenderung von FW-Regel und abgewiesenes IP-Paket" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4750_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4750_02") echo "Executing test case "TIP1-A_4750-02 Firewall-Protokollierung \(Neustart LAN\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4750_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4750_03") echo "Executing test case "TIP1-A_4750-03 Firewall-Protokollierung \(Neustart WAN\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4750_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4750_04") echo "Executing test case "TIP1-A_4750-04 Firewall-Protokollierung \(Martian Packets\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4750_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;	
	"TIP1_A_4759_07") echo "Executing test case "TIP1-A_4759-07 NET_TI_GESICHERTE_FD" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_07.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_08") echo "Executing test case "TIP1-A_4759-08 NET_SIS" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_08.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_01") echo "Executing test case "TIP1-A_4760-01 ANLW_WAN_IP_ADDRESS" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
			
	"TIP1_A_4760_02") echo "Executing test case "TIP1-A_4760-02 ANLW_WAN_SUBNETMASK" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_04") echo "Executing test case "TIP1-A_4760-04 Ueberlappung mit NET_TI_DEZENTRAL" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_05") echo "Executing test case "TIP1-A_4760-05 Ueberlappung mit NET_TI_ZENTRAL" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_05.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_06") echo "Executing test case "TIP1-A_4760-06 Ueberlappung mit NET_TI_OFFENE_FD" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_07") echo "Executing test case "TIP1-A_4760-07 Ueberlappung mit NET_TI_GESICHERTE_FD" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_07.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_08") echo "Executing test case "TIP1-A_4760-08 Ueberlappung mit NET_SIS" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_08.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_11") echo "Executing test case "TIP1-A_4760-11 Ueberlappung mit ANLW_LAN_NETWORK_SEGMENT" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_11.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4762_01") echo "Executing test case "TIP1-A_4762-01 Konfigurationsparameter Firewall-Schnittstelle" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4762_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4761_01") echo "Executing test case "TIP1-A_4761-01 Konfiguration Anbindung LAN-WAN \(ANLW_INTERNET_MODUS\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4761_02") echo "Executing test case "TIP1-A_4761-02 Konfiguration Anbindung LAN-WAN \(ANLW_INTRANET_ROUTES\)" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4761_03") echo "Executing test case "TIP1-A_4761-03 Konfiguration Anbindung LAN-WAN "\(ANLW_WAN_ADAPTER_MODUS\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;	
	
	"TIP1_A_4761_04") echo "Executing test case "TIP1-A_4761-04 Konfiguration Anbindung LAN-WAN "\(ANLW_LEKTR_INTRANET_ROUTES\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4761_06") echo "Executing test case "TIP1-A_4761-06 Konfiguration Anbindung LAN-WAN "\(ANLW_IA_BESTANDSNETZE=AN\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4761_07") echo "Executing test case "TIP1-A_4761-07 Konfiguration Anbindung LAN-WAN "\(ANLW_IA_BESTANDSNETZE=AUS\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_07.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4759_05") echo "Executing test case "TIP1-A_4759-05 Ueberlappung mit NET_TI_ZENTRAL "\(interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_05.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4759_06") echo "Executing test case "TIP1-A_4759-06 Konfiguration Anbindung LAN/WAN \(ANLW_IA_BESTANDSNETZE=AN\)  ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4759_07") echo "Executing test case "TIP1-A_4759-07 Konfiguration Anbindung LAN/WAN \(ANLW_IA_BESTANDSNETZE=AUS\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_07.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;
	
	"TIP1_A_4760_03") echo "Executing test case "TIP1-A_4760-03 Nur Einsichtnahme bei aktiviertem DHCP-Client "\(Interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_11") echo "Executing test case "TIP1-A_4759-11 Ueberlappung mit ANLW_LEKTR_INTRANET_ROUTES "\(interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_11.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_12") echo "Executing test case "TIP1-A_4759-12 Aenderbarkeit von Parametern "\(interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_12.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4748_01") echo "Executing test case "TIP1-A_4748-01 Firewall Routing-Regeln "\(Verwerfen von DHCP-Paketen VPN_TI\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4748_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4748_03") echo "Executing test case "TIP1-A_4748-03 Firewall Routing-Regeln "\(Abweisen IPSEC-Pakete\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4748_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_02") echo "Executing test case "TIP1-A_4759-02 ANLW_LAN_SUBNETMASK" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_03") echo "Executing test case "TIP1-A_4759-03 Nur Einsichtnahme bei aktiviertem DHCP-Client "\(Interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4745_02") echo "Executing test case "TIP1-A_4745-02  - - Ping verwerfen" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4745_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_01") echo "Executing test case "TIP1-A_4759-01 ANLW_LAN_IP_ADDRESS" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5414_01") echo "Executing test case "TIP1-A_5414-01 Initialisierung -Anbindung LAN-WAN-" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5414_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt 
	;;
	
	"TIP1_A_4755_01") echo "Executing test case "TIP1-A_4755-04 TUC_KON_306 WAN-Adapter initialisieren "TUC_KON_306 WAN-Adapter initialisieren nach manuellem DHCP-Renew"
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4755_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_4755_04") echo "Executing test case "TIP1-A_4755-04 TUC_KON_306 WAN-Adapter initialisieren "\(MGM_LU_ONLINE=Disabled\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4755_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4745_03") echo "Executing test case "TIP1-A_4745-03  - - Erlaubte Ping Kommunikation" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4745_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4762_02") echo "Executing test case "TIP1-A_4762-02 Erweitertes Security-Logging" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4762_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5406_01") echo "Executing test case "TIP1-A_5406-01" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5406_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_5407_01") echo "Executing test case "TIP1-A_5407-01" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_5407_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4759_04") echo "Executing test case "TIP1-A_4759-04 Ueberlappung mit NET_TI_DEZENTRAL "\(interaktiv\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4759_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4753_03") echo "Executing test case "TIP1-A_4753-03" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4753_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4747_01") echo "Executing test case "TIP1-A_4747-01 Firewall- Einschraenkungen der IP-Protokolle" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4747_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4748_02") echo "Executing test case "TIP1-A_4748-02 Konnektor verwirft DHCP" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4748_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4760_04") echo "Executing test case "TIP1-A_4760-04 Ueberlappung mit NET TI DEZENTRAL" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4760_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4761_05") echo "Executing test case "TIP1-A_4761-05 Konfiguration Anbindung LAN-WAN "\(ANLW_SERVICE_TIMEOUT\) ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4761_05.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt  
	;;	
			
	"TIP1_A_4755_02") echo "Executing test case "TIP1-A_4755-02 Manuelle Konfiguration" ..."
		TestFaelle/05_Paket5/05_04_Netzkonnektor/05_04_01_Anbindung_LAN_WAN/05_04_01_01_Anbindung_LAN_WAN/TIP1_A_4755_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_4718_02") echo "Executing test case "TIP1-A_4718-02 TUC_KON_272 - Initialisierung Protokollierungsdienst - Fehler 4153" ..."
		TestFaelle/06_Paket_OPB/06_02_TUC_KON_272/06_02_01_Initialisierung_Protokollierungsdienst/TIP1_A_4718_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5326_01") echo "Executing test case "GS-A_5326-01 Performance - Konnektor - Hauptspeicher" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_01_Hauptspeicher/GS_A_5326_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5333_01") echo "Executing test case "GS-A_5333-01 Performance - Konnektor - TLS Session Resumption Intermediär" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_03_TLS_Session_Resumption/GS_A_5333_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5333_02") echo "Executing test case "GS-A_5333-02 Performance - Konnektor - ohne TLS Session Resumption Intermediär" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_03_TLS_Session_Resumption/GS_A_5333_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_01") echo "Executing test case "GS_A_5328_01 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_02") echo "Executing test case "GS_A_5328_02 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_03") echo "Executing test case "GS_A_5328_03 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_04") echo "Executing test case "GS_A_5328_04 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_04.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_05") echo "Executing test case "GS_A_5328_05 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_05.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_06") echo "Executing test case "GS_A_5328_06 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_07") echo "Executing test case "GS_A_5328_07 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_07.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"GS_A_5328_08") echo "Executing test case "GS_A_5328_08 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_08.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_09") echo "Executing test case "GS_A_5328_09 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_09.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_10") echo "Executing test case "GS_A_5328_10 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_10.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"GS_A_5328_11") echo "Executing test case "GS_A_5328_11 Manuelle Konfiguration" ..."
		TestFaelle/06_Paket_OPB/06_01_Performance_Konnektor/06_01_02_TLS_Handshake/GS_A_5328_11.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_2190_EmptyConversationID") echo "Executing test case "VSDM_A_2190_EmptyConversationID.sh" ..."
		TestFaelle/07_Paket_Self_Specified_TestCases/vsdm/VSDM_A_2190_EmptyConversationID.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"VSDM_A_2190_InvalidConversationID") echo "Executing test case "VSDM_A_2190_InvalidConversationID.sh" ..."
		TestFaelle/07_Paket_Self_Specified_TestCases/vsdm/VSDM_A_2190_InvalidConversationID.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_6103_01") echo "Executing test case "TIP1_A_6103_01" ..."
		TestFaelle/06_Paket6/06_01_KSR/TIP1_A_6103_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;
	
	"TIP1_A_3314_03") echo "Executing test case "TIP1-A_3314-03 Inhalt Update-Paket - Adressierung von Documentationfiles" ..."
		TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3314_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

	"TIP1_A_5449_06") echo "Executing test case "TIP1_A_5449_06 Zertifikatsprüfung bei Nichterreichbarkeit des OCSP" ..."
		TestFaelle/05_Paket5/05_01_Uebergreifende-Spezifikation/05_01_03_Spezifikation_PKI/TIP1_A_5449_06.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
	;;

        "TIP1_A_3314_01") echo "Executing test case "TIP1-A_3314-01 Inhalt Update-Paket - Hersteller-Update-Information" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3314_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_3314_02") echo "Executing test case "TIP1-A_3314-02 Inhalt Update-Paket - Firmware.Firmwarefiles.Filename" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3314_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_3316_01") echo "Executing test case "TIP1-A_3316-01 Firmware-Gruppenkonzept Informationen fuer den Konfigurationsdienst" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3316_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_3895_01") echo "Executing test case "TIP1-A_3895-01 Inhalt Update-Paket – Konnektor FirmwareFiles" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3895_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
        
        "TIP1_A_3895_02") echo "Executing test case "TIP1-A_3895-02 Inhalt Update-Paket – Konnektor FirmwareFiles" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3895_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
        
        "TIP1_A_3896_01") echo "Executing test case "TIP1-A_3896-01 Signatur der Update-Informationen durch Konnektorhersteller" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_3896_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_5159_01") echo "Executing test case "TIP1-A_5159-01 Inhalt Update-Paket – Firmware-Gruppen-Information" ..."
                TestFaelle/06_Paket6/06_01_KSR/TIP1_A_5159_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4820_02") echo "Executing test case "TIP1-A_4820-02 alternativer Werksreset \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4820_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4820_02") echo "Executing test case "TIP1-A_4820-02 alternativer Werksreset \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4820_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4821_03") echo "Executing test case "TIP1-A_4821-03 Defaultwerte \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4821_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4822_02") echo "Executing test case "TIP1-A_4822-02 Defaultwerte \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4822_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4823_02") echo "Executing test case "TIP1-A_4822-03 Defaultwerte \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4823_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_4825_01") echo "Executing test case "TIP1-A_4825-01 Freischalten des Konneḱtors \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4825_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_5011_01") echo "Executing test case "TIP1-A_5011-01 Import von Kartenterminal-Informationen \(interaktiv\)" ..."
                TestFaelle/01_Paket1/01_02_Anwendungskonnektor/01_02_06_Kartenterminaldienst/01_02_06_Kartenterminaldienst/TIP1_A_5011_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

        "TIP1_A_5652_03") echo "Executing test case "TIP1-A_5652-03 Defaultwerte \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5652_03.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
        
		"TIP1_A_4390_01") echo "Executing test case "TIP1-A_4390-01 Unterstützung der Operation registerKonnektor" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4390_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
         
		"TIP1_A_4391_01") echo "Executing test case "TIP1-A_4391-01 Unterstützung der Operation deregisterKonnektor" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_4391_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
		
        "TIP1_A_5698_01") echo "Executing test case "TIP1-A_5698-01 Löschen von Karternterminaleinträgen \(interaktiv\)" ..."
                TestFaelle/03_Paket3/03_01_Konnektormanagement/03_01_01_Konnektormanagement/TIP1_A_5698_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
        
        "TIP1_A_6478_02") echo "Executing test case "TIP1-A_6478-02 - Erlaubte SICCT-Kommandos bei CT.CONNECTED=Nein" ..."
                TestFaelle/06_Paket6/06_02_SICCT/TIP1_A_6478_02.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;

		"TIP1_A_4504_01") echo "Executing test case "TIP1-A_4504-01 - Keine Administratorinteraktionen bei Einsatz mehrerer gSMC-Ks \(interaktiv\)" ..."
                TestFaelle/07_Paket7/07_01_KSR/TIP1_A_4504_01.sh  2>&1  |  tee Protokollierung/$EXECUTION_MODUS/$testCaseName.txt
        ;;
	        *) echo "No such test case \"$testCaseName\" implemented yet!"
        ;;
	esac
	
	#--------------------------------------------------
	
	# Invoke time protocol
	java -cp $KONNEKTOR_TS_CLASS_PATH  konnektor.testsuite.general.utils.TimeProtocol Protokollierung/$EXECUTION_MODUS/$testCaseName.txt 
	# Invoke finally the test oracle
	java -cp $KONNEKTOR_TS_CLASS_PATH  konnektor.testsuite.general.utils.TestOracle Protokollierung/$EXECUTION_MODUS/$testCaseName.txt $KONNEKTOR_TYPE $testCaseName
	
	# check if the test case has failed and extract the logs
	# TODO: improve the grep by adding a regex for the string
	grep "Gesamt-Testfall: FAILED" Protokollierung/$EXECUTION_MODUS/$testCaseName.txt > /dev/null
	if [ $? -eq 0 ]
	then
		TC_FAILED="yes"
	else
		TC_FAILED="no"
	fi
	
	if [ "w$ALWAYS_SAVE_PCAP" = "wyes" ]
	then
	  save_pcap_logs $testCaseName
    fi  
	  
	if [ "x$TC_FAILED" = "xyes" ] || [ "x$FORCE_APPEND_LOGS" = "xyes" ]
	then
		echo ""
		echo ""
		echo "Einsammeln der Logs für den Testfall ..."
		
		echo "sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP \"rm -f konnektorLog.tar.gz\""
		sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP "rm -f konnektorLog.tar.gz"
		
		echo "sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP \"tar cf konnektorLog.tar $KONNEKTOR_LOG_PATH\""
		sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP "tar cf konnektorLog.tar $KONNEKTOR_LOG_PATH 2> /dev/null"
		
		echo "sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP \"gzip konnektorLog.tar\""
		sshpass -p  $KONNEKTOR_PASSWORD  ssh -p $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP "gzip konnektorLog.tar"
		
		echo "sshpass -p  $KONNEKTOR_PASSWORD   scp -P $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP:konnektorLog.tar.gz Protokollierung/$EXECUTION_MODUS/$testCaseName\_konnLog.tar.gz"
		sshpass -p  $KONNEKTOR_PASSWORD  scp -P $KONNEKTOR_PORT root@$KONNEKTOR_MNG_IP:konnektorLog.tar.gz Protokollierung/$EXECUTION_MODUS/$testCaseName\_konnLog.tar.gz

	    if [ "w$ALWAYS_SAVE_PCAP" != "wyes" ]
	    then
	      save_pcap_logs $testCaseName
        fi
		
		if [ "x$RESET_DOCKER_ENV" = "xyes" ]
		then
			DOCKER_BASE_DIR=~/docker-build
			if [ -f $DOCKER_BASE_DIR/.env ] # unifizierte Docker-Testumgebung?
			then
				YML_FILENAME=docker-compose.yml
			else
				DOCKER_BASE_DIR=~/testnetz
				if [ -f $DOCKER_BASE_DIR/.env ] # FHI Docker-Testumgebung?
				then
					# Docker env-Variablen einlesen
					. $DOCKER_BASE_DIR/.env
					
					if [ -n "$KONN_LAN_2_INTERFACE" ]
					then
						YML_FILENAME=docker-compose-FHI-2lan-interfaces.yml
					else
						YML_FILENAME=docker-compose-FHI.yml
					fi
				else
					DOCKER_BASE_DIR=unknown_dir
					YML_FILENAME=unknown_file
				fi
			fi
			DOCKER_CONTAINER_LOGS_FILENAME=Protokollierung/$EXECUTION_MODUS/$testCaseName\_dockLog
			
			docker-compose -f $DOCKER_BASE_DIR/$YML_FILENAME logs -t --no-color | gzip -c > $DOCKER_CONTAINER_LOGS_FILENAME.gz
		fi
		
		# now we have to check whether the test case has been analysed
		grep -i "ORSFT\|ORSKONCC\|KONN-\|KONNPT\-" Protokollierung/$EXECUTION_MODUS/$testCaseName.txt > /dev/null
		if [ $? -ne 0 ] && [ "x$TC_FAILED" = "xyes" ]
		then
			# in case the test case is not analysed
			
			# check if the directory for not analysed logs execution indeed exists
			#
			if [ ! -d  Protokollierung/not\_analysed\_Inconclusive\_$EXECUTION_MODUS ]; then
				#		echo "Das eingestellte Protokollierungsverzeichnis \""Protokollierung/$EXECUTION_MODUS"\" existiert nicht!!!"
				#		echo "Leaving ..."
				#		exit 1
				mkdir -p Protokollierung/not\_analysed\_Inconclusive\_$EXECUTION_MODUS ;
			fi
			
			# move the results to the new directory
			echo ""
			echo "Testfall ist aktuell INCONCLUSIVE ..."
			echo "Die Ergebnisse werden ins Verzeichnis \"Protokollierung/not\_analysed\_Inconclusive\_$EXECUTION_MODUS\" verschoben."
			echo ""  
			echo "mv Protokollierung/$EXECUTION_MODUS/$testCaseName* Protokollierung/not\_analysed\_Inconclusive\_$EXECUTION_MODUS"
			mv Protokollierung/$EXECUTION_MODUS/$testCaseName* Protokollierung/not\_analysed\_Inconclusive\_$EXECUTION_MODUS
		fi
	fi
}


function saveAllLogs {
	# get the test case name
    testCaseName=$1;
    
    java -cp $KONNEKTOR_TS_CLASS_PATH  konnektor.testsuite.general.utils.SaveAllLogs Protokollierung/$EXECUTION_MODUS/ $testCaseName
    
}


function save_pcap_logs {
	# get the test case name
    testCaseName=$1;
    	
		if [ "w$START_PCAP_LOGGING" = "wyes" ]
		then
			
			echo "Die PCAP-Dateien werden im Protokollierungsverzeichnis abgelegt."
			echo ""
			
			#stop tcpdump on the NTP-server
			echo "ssh root@$NTP_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$NTP_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom NTP-Server kopiert."
			echo ""
			echo "scp root@$NTP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$NTP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_NTP_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_NTP_Server_Traffic.txt
			
			#stop tcpdump on the DNS TI server
			echo "ssh root@$DNS_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$DNS_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom DNS TI Server kopiert."
			echo ""
			echo "scp root@$DNS_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$DNS_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_TI_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_TI_Server_Traffic.txt

			#stop tcpdump on the DNS PUBLIC server
			echo "ssh root@$DNS_PUBLIC_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$DNS_PUBLIC_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom DNS PUBLIC Server kopiert."
			echo ""
			echo "scp root@$DNS_PUBLIC_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$DNS_PUBLIC_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_PUBLIC_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_PUBLIC_Server_Traffic.txt

			#stop tcpdump on the OCSP TI server
			echo "ssh root@$OCSP_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$OCSP_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom OCSP TI Server kopiert."
			echo ""
			echo "scp root@$OCSP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$OCSP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_OCSP_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_OCSP_Server_Traffic.txt
			
			#stop tcpdump on the ROUTER NAT server
			echo "ssh root@$ROUTER_NAT_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$ROUTER_NAT_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom ROUTER NAT Server kopiert."
			echo ""
			echo "scp root@$ROUTER_NAT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$ROUTER_NAT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_ROUTER_NAT_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_ROUTER_NAT_Server_Traffic.txt
			
			#stop tcpdump on the VSDM-server
			echo "ssh root@$VSDM_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$VSDM_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom VSDM-Server kopiert."
			echo ""
			echo "scp root@$VSDM_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$VSDM_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_VSDM_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_VSDM_Server_Traffic.txt
			
			#stop tcpdump on the INTERMEDIAER_TI_IP-server
			echo "ssh root@$INTERMEDIAER_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$INTERMEDIAER_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom INTERMEDIAER-Server kopiert."
			echo ""
			echo "scp root@$INTERMEDIAER_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$INTERMEDIAER_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_INTERMEDIAER_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_INTERMEDIAER_Server_Traffic.txt
			
			#stop tcpdump on the KSR-server
			echo "ssh root@$KSR_TI_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$KSR_TI_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom KSR-Server kopiert."
			echo ""
			echo "scp root@$KSR_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$KSR_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KSR_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KSR_Server_Traffic.txt

			#stop tcpdump on the KT-A
			echo "ssh root@$KT_A_MANAGEMENT_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_A_MANAGEMENT_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom KT-A kopiert."
			echo ""
			echo "scp root@$KT_A_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$KT_A_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_A_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_A_Server_Traffic.txt

			#stop tcpdump on the KT-B
			echo "ssh root@$KT_B_MANAGEMENT_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_B_MANAGEMENT_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom KT-B kopiert."
			echo ""
			echo "scp root@$KT_B_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$KT_B_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_B_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_B_Server_Traffic.txt

			#stop tcpdump on the KT-C
			echo "ssh root@$KT_C_MANAGEMENT_IP \"pkill tcpdump\""
			sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_C_MANAGEMENT_IP "pkill tcpdump > /dev/null"
			echo "Der Pakettrace wird vom KT-C kopiert."
			echo ""
			echo "scp root@$KT_C_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
			sshpass -p $TI_ROOT_PASSWORD scp root@$KT_C_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
			/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
			echo ""
			echo ""
			cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_C_Server_Traffic.pcap
			cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_C_Server_Traffic.txt

		else
			#echo "NOTE: Script $SCRIPT_FILENAME wurde ohne Aktion ausgefuehrt."
			if [ "w$START_PCAP_LOGGING_NTP" = "wyes" ]
			then
				echo "Die PCAP-Dateien werden im Protokollierungsverzeichnis abgelegt."
				
				#stop tcpdump on the NTP-server
				echo "ssh root@$NTP_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$NTP_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom NTP-Server kopiert."
				echo ""
				echo "scp root@$NTP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$NTP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_NTP_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_NTP_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_DNS_TI" = "wyes" ]
			then
				#stop tcpdump on the DNS TI server
				echo "ssh root@$DNS_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$DNS_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom DNS TI Server kopiert."
				echo ""
				echo "scp root@$DNS_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$DNS_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_TI_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_TI_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_DNS_PUBLIC" = "wyes" ]
		 	then
				#stop tcpdump on the DNS PUBLIC server
				echo "ssh root@$DNS_PUBLIC_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$DNS_PUBLIC_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom DNS PUBLIC Server kopiert."
				echo ""
				echo "scp root@$DNS_PUBLIC_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$DNS_PUBLIC_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_PUBLIC_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_DNS_PUBLIC_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_OCSP" = "wyes" ]
			then
				#stop tcpdump on the OCSP TI server
				echo "ssh root@$OCSP_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$OCSP_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom OCSP TI Server kopiert."
				echo ""
				echo "scp root@$OCSP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$OCSP_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_OCSP_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_OCSP_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_ROUTER_NAT" = "wyes" ]
			then
				#stop tcpdump on the ROUTER NAT server
				echo "ssh root@$ROUTER_NAT_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$ROUTER_NAT_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom ROUTER NAT Server kopiert."
				echo ""
				echo "scp root@$ROUTER_NAT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$ROUTER_NAT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_ROUTER_NAT_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_ROUTER_NAT_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_VSDM" = "wyes" ]
			then
				#stop tcpdump on the VSDM-server
				echo "ssh root@$VSDM_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$VSDM_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom VSDM-Server kopiert."
				echo ""
				echo "scp root@$VSDM_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$VSDM_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF-r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_VSDM_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_VSDM_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_INTERMEDIAER" = "wyes" ]
			then
				#stop tcpdump on the INTERMEDIAER_TI_IP-server
				echo "ssh root@$INTERMEDIAER_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$INTERMEDIAER_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom INTERMEDIAER-Server kopiert."
				echo ""
				echo "scp root@$INTERMEDIAER_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$INTERMEDIAER_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_INTERMEDIAER_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_INTERMEDIAER_Server_Traffic.txt
			fi
	
			if [ "w$START_PCAP_LOGGING_KSR" = "wyes" ]
			then
				#stop tcpdump on the KSR-server
				echo "ssh root@$KSR_TI_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$KSR_TI_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom KSR-Server kopiert."
				echo ""
				echo "scp root@$KSR_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$KSR_TI_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KSR_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KSR_Server_Traffic.txt
			fi
			
			if [ "w$START_PCAP_LOGGING_KT_A" = "wyes" ]
			then
				#stop tcpdump on the KT-A
				echo "ssh root@$KT_A_MANAGEMENT_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_A_MANAGEMENT_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom KT-A kopiert."
				echo ""
				echo "scp root@$KT_A_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$KT_A_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_A_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_A_Server_Traffic.txt
			fi			

			if [ "w$START_PCAP_LOGGING_KT_B" = "wyes" ]
			then
				#stop tcpdump on the KT-B
				echo "ssh root@$KT_B_MANAGEMENT_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_B_MANAGEMENT_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom KT-B kopiert."
				echo ""
				echo "scp root@$KT_B_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$KT_B_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_B_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_B_Server_Traffic.txt
			fi

			if [ "w$START_PCAP_LOGGING_KT_C" = "wyes" ]
			then
				#stop tcpdump on the KT-C
				echo "ssh root@$KT_C_MANAGEMENT_IP \"pkill tcpdump\""
				sshpass -p $TI_ROOT_PASSWORD ssh root@$KT_C_MANAGEMENT_IP "pkill tcpdump" > /dev/null
				echo "Der Pakettrace wird vom KT-C kopiert."
				echo ""
				echo "scp root@$KT_C_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap"
				sshpass -p $TI_ROOT_PASSWORD scp root@$KT_C_MANAGEMENT_IP:Server_Traffic.pcap ../tmp/$testCaseName\_Server_Traffic.pcap 
				/usr/sbin/tcpdump $PCAP_VERBOSE_CONF -r ../tmp/$testCaseName\_Server_Traffic.pcap > ../tmp/$testCaseName\_Server_Traffic.txt
				echo ""
				echo ""
				cp ../tmp/$testCaseName\_Server_Traffic.pcap  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_C_Server_Traffic.pcap
				cp ../tmp/$testCaseName\_Server_Traffic.txt  Protokollierung/$EXECUTION_MODUS/$testCaseName\_KT_C_Server_Traffic.txt
			fi
		fi	
}


#####################################################
### The main function of the Test-Management script
#####################################################
function main {
	echo ""
	echo ""
	
	echo "Skript zur Steuerung des Konnektor-Tests ..."
	echo "--------------------------------------------"
	
	if [ $NUMBER_OF_ARGS -eq 0 ] 
	then
		# in case of no arguments
		
		echo "Starten aller Testfaelle in der Liste ..."
		
		runAll
	else
		# in case of test case names 
		for i in $ARGS
		do
			# call the init function
			init
			echo "Starting test case:\"$i\""
			
			runTestCase $i
			saveAllLogs $i
		done
	fi
	
	echo "--------------------------------------------"
	echo "Testfallausfuehrung abgeschlossen!"
	echo ""
	echo ""
}


# call the main function
main
