# ~/.bashrc: executed by bash(1) for non-login shells.

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
#PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
#umask 022
#PROMPT_TRIMDIR=($?)\[\033[‌​00m\]\$
##export PS1='\u@\h\[\033[0;38m\] :-) > '
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '
#export PS1='-> '

#export PATH=$PATH:/root/testnetz
export PATH=$PATH:.:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/:
#export PATH=$PATH:.:

force_color_prompt=yes

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias konn='sshpass -p123456 ssh -p2222 root@10.10.8.15'
alias konn_reboot='sshpass -p123456 ssh -p2222 root@10.10.8.15 "/sbin/reboot"'
alias ti_s='sshpass -p123456 ssh root@10.60.5.3'
alias sis_s='sshpass -p123456 ssh root@10.60.5.4'

alias test_path='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd'
alias sichere_protokolle='/etc/cron.daily/SichereProtokolle'
alias ocsp='sshpass -p123456 ssh root@10.60.5.71'

alias build_base_image='cd ~/testnetz/testnetz/base-image ; ./build.sh'
alias build_image_konzentrator='cd ~/testnetz/testnetz/base-image-konzentrator ; ./build.sh'

alias run1='clear;echo "" ; echo "";printf "%*s\n" 60 "Alle Testfälle Runplan" ; echo "" ; echo "" ; sleep 3 ; cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET1/startAutomatedRunPlans.sh'
alias run2='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET2/startAutomatedRunPlans.sh'
alias run5='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET5/startAutomatedRunPlans.sh'
alias run_reg='clear;echo ""; echo "";printf "%*s\n" 60 "REG+SAM TF werden jetzt gestartet" ; printf "%*s\n" 100 "*********************************"; echo "" ; echo ""; sleep 3; cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET_REG/startAutomatedRunPlans.sh'

alias go_tf_folder='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd'

alias run_all_withous_reg='clear;echo ""; echo "";printf "%*s\n" 60 "Es werden alle TF ohne REG+SAM gestartet" ; printf "%*s\n" 100 "*********************************"; echo "" ; echo ""; sleep 3; cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET4/startAutomatedRunPlans.sh'

export java_classen='/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/bin/:../bin:/root/.p2/pool/plugins/org.junit_4.12.0.v201504281640/*:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/libthrift-0.9.3.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/json-simple-1.1.1.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/common/xercesImpl-2.9.0.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/guava-23.6-jre.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/gson-2.8.2.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/client-combined-3.12.0.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/byte-buddy-1.8.3.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-codec-1.10.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-exec-1.3.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/commons-logging-1.2.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpclient-4.5.3.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/httpcore-4.4.6.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okhttp-3.9.1.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/selenium/okio-1.13.0.jar:/root/.p2/pool/plugins/*:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/konnektor-api/konnektor-api-1.13.1.jar:/root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/lib/fhi-cardterminalsimulation/de.fraunhofer.fokus.cardterminalsimulation.client-0.10.0.jar'
export karten_manipulate='/root/workspaceNeon/Web/src'

alias k_m='cd /root/workspaceNeon/Web/src'

alias karten_insert='PWD_BKUP=$(pwd) ; cd /root/workspaceNeon/Web/src;  export export CT_SIM=FHI ;  export KT_A_MANAGEMENT_IP="10.60.5.200" ; export KT_B_MANAGEMENT_IP="10.60.5.201" ; export KT_C_MANAGEMENT_IP="10.60.5.202" ; java  -cp $java_classen:. KT_SIM_Cards_Prepare insert ; cd $PWD_BKUP'
alias karten_remove='PWD_BKUP=$(pwd) ; cd /root/workspaceNeon/Web/src;  export export CT_SIM=FHI ;  export KT_A_MANAGEMENT_IP="10.60.5.200" ; export KT_B_MANAGEMENT_IP="10.60.5.201" ; export KT_C_MANAGEMENT_IP="10.60.5.202" ; java  -cp $java_classen:. KT_SIM_Cards_Prepare remove ; cd $PWD_BKUP'

alias accesscontrol='PWD_BKUP=$(pwd) ; clear;echo "" ; echo "";printf "%*s\n" 60 "Es werden Zugriffsberechtigungen eingestellt" ; echo "Bitte, warten"  ; cd /root/workspaceNeon/Web/src; java  -cp $java_classen:. ConstTest ; cd $PWD_BKUP'
alias accesscontrol_tomf_0_7_2='PWD_BKUP=$(pwd) ; cd /root/workspaceNeon/Web/src; java  -cp $java_classen:. ConstTest_Tomf_0_7_2 ; cd $PWD_BKUP'
alias accesscontrol_clear='PWD_BKUP=$(pwd) ; cd /root/workspaceNeon/Web/src; java  -cp $java_classen:. ConstTestClear ; cd $PWD_BKUP'
alias ct_connect='PWD_BKUP=$(pwd) ; cd /root/workspaceNeon/Web/src; java  -cp $java_classen:. Setup_CT ; cd $PWD_BKUP'

alias fhi_ctsim_start='cd /root/fhi-ct-sim-docker ; docker-compose down ; docker-compose up -d'

alias docker_env_restart='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; ./HelperScripts/stop_Docker_TestEnvironment.sh ;  ./HelperScripts/start_Docker_TestEnvironment.sh'

alias run_schatten='cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; pwd ; ./Ausfuehrungssessions/MAI_2017/PAUL/PAKET_SCHATTEN/startAutomatedRunPlans.sh'

alias zeit_konn='sshpass -p123456 ssh -p2222 root@10.10.8.15 "date"'
alias zeit_ntp='sshpass -p123456 ssh  root@ntp "date"'

#testnetz
alias ntp_start='sshpass -p123456 ssh root@10.60.5.68 "service ntp start"'
alias ntp_stop='sshpass -p123456 ssh root@10.60.5.68 "service ntp stop"'
alias ntp='sshpass -p123456 ssh root@10.60.5.68'

alias ti_ipsec_start='sshpass -p '123456' ssh root@10.60.5.3 "ipsec start"'
alias ti_ipsec_stop='sshpass -p '123456' ssh root@10.60.5.3 "ipsec stop"'

alias sis_ipsec_start='sshpass -p '123456' ssh root@10.60.5.4 "ipsec start"'
alias sis_ipsec_stop='sshpass -p '123456' ssh root@10.60.5.4 "ipsec stop"'

alias docker_logs='PWD_BKUP=$(pwd) ; cd /root/workspace.docker_branch/TestSuite-Konnektor-T-Systems/TestFallSteuerung ; ./HelperScripts/attachDockerContainerLogs.sh ; cd $PWD_BKUP'

if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

zugriffsberechtigungen(){
 PWD_BKUP=$(pwd)
 clear
 echo "" 
 echo ""
 printf "%*s\n" 60 "Es werden Zugriffsberechtigungen eingestellt" 
 echo "Bitte, warten"  
 cd /root/workspaceNeon/Web/src
 java  -cp $java_classen:. ConstTest 
 cd $PWD_BKUP
}
export -f zugriffsberechtigungen

remove_karten_sim(){
 PWD_BKUP=$(pwd)
 cd /root/workspaceNeon/Web/src
 export export CT_SIM=FHI
 export KT_A_MANAGEMENT_IP="10.60.5.200" 
 export KT_B_MANAGEMENT_IP="10.60.5.201"
 export KT_C_MANAGEMENT_IP="10.60.5.202"
 java  -cp $java_classen:. KT_SIM_Cards_Prepare remove
 cd $PWD_BKUP
}
export -f remove_karten_sim

insert_karten_sim(){
 PWD_BKUP=$(pwd)
 cd /root/workspaceNeon/Web/src
 export export CT_SIM=FHI
 export KT_A_MANAGEMENT_IP="10.60.5.200" 
 export KT_B_MANAGEMENT_IP="10.60.5.201"
 export KT_C_MANAGEMENT_IP="10.60.5.202"
 java  -cp $java_classen:. KT_SIM_Cards_Prepare insert
 cd $PWD_BKUP
}
export -f insert_karten_sim

