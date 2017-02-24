#!/bin/bash
# This script will attempt to check for common issues on the PowerVille LB 
# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
OFFSET='\033[60G'
echo_success(){
  echo -en \\033
  echo -en "${OFFSET}[  ${GREEN}OK${NC}  ]";
}
echo_failure(){
echo -en "${OFFSET}[${RED}FAILED${NC}]";
}
STEP_OK=0
step() {
    echo -n -e "$@"
    echo -e "#########################################################################" >> $LOG
    echo -e "STEP -  $@" >> $LOG
    STEP_OK=0
}
next() {
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo
    echo -e "STEP result">> $LOG
    echo -e "#########################################################################" >> $LOG
    return $STEP_OK
}
log(){
	echo "$@" >> $LOG
}

logx(){
	echo "----------------------------------------------------------------------------" &>> $LOG
	echo "$@" >> $LOG
	echo "---------------------" &>> $LOG
	"$@" &>> $LOG
}
setpass(){
STEP_OK=0
}
setfail(){
STEP_OK=1
}

###########################################################################
#######                Start of script                             ########
###########################################################################
hostname=`hostname`
OUTFILE="lbaudit-$hostname.tgz"
LOG="lbaudit-$hostname.log"

TMPPATH="/var/tmp/lbaudit"

starttime=`date +"%Y-%m-%d_%H-%M-%S"`
echo "Starting Audit - $starttime" > $LOG
logger -t SCRIPT  "Starting LB Audit via $0"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking System Requirements"
echo "----------------------------------------------------------------------------" &>> $LOG
	TARGET=4
step "     CPUs on system (>${TARGET})..."
	RESULT=$(lscpu | grep -P '(?=^CPU\(s\):.*)' | cut -c22- );
	RESULT=$(expr $RESULT / 1)
	if [ $RESULT -ge $TARGET ]
	then
		setpass
	else
		echo -en "\033[70G$RESULT detected"
		setfail
	fi
#TODO - Test for Family as well
next  
echo "----------------------------------------------------------------------------" &>> $LOG
	TARGET=8
step "     Installed Memory (>${TARGET})..."
	RESULT=$(cat /proc/meminfo | grep MemTotal: | cut -c15- | rev | cut -c3- | rev);
	RESULT=$(expr $RESULT / 1000000)
	if [ $RESULT -ge  $TARGET ]
	then
		setpass	 
	else
		echo -en "\033[70G${RESULT}GB detected"
		setfail  
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
	TARGET=40
step "     Disk Space (>${TARGET})..."
	RESULT=$(df -h | grep ^/dev | grep /$ | awk '{ print $2 " "  }' | sed s/G/000000/g | sed s/M/000/g)
	RESULT=$(expr $RESULT / 1000000)
	if [ $RESULT -ge  $TARGET ]
	then
		setpass
	else
		echo -en "\033[70G${RESULT}GB detected"
		setfail
		
	fi
next;
echo "----------------------------------------------------------------------------" &>> $LOG
echo

log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "Checking frequently misconfigured items"
echo "Checking frequently misconfigured items"
step "     SELinux disabled"
	RESULT=$(sestatus)
	if grep -q disabled <<<$RESULT; 
	then
		setpass
	else
		setfail
	fi
next;
echo "----------------------------------------------------------------------------" &>> $LOG
step "     etc/hostname"
log "hostname set to short form"
SHORTHOSTNAME=$(hostname -s)
RESULT=$(cat /etc/hostname)
	if [ $RESULT == $SHORTHOSTNAME ] ; 
	then
		setpass
	else
		setfail
	fi
next; 
step "     hostnamectl"
log "hostname set to short form"
	logx hostnamectl
	RESULT=$(hostnamectl | grep -oP '(?<=Static hostname: ).*')
	if [ $RESULT == $SHORTHOSTNAME ] ; 
	then
		setpass
	else
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     hosts file hostname on 127.0.0.1"
log "etc/hosts should have the fqdn and hostname set"
	logx cat /etc/hosts 
	RESULT=$(hostnamectl | grep -oP '(?<=Static hostname: ).*')
	if grep -P "127.0.0.1.* ${SHORTHOSTNAME} " /etc/hosts &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     hostname ping" 
log "Check that you can ping the hostname, confirm this to your dir"
	if ping -c 1 -i 0.5 ${SHORTHOSTNAME}  &>> $LOG; 
	then
		setpass
	else
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     internet ping"
log "Check that you can ping the an internet location"
	if ping -c 1 -i 0.5 8.8.8.8   &>> $LOG; 
	then
		setpass
	else
		setfail
	fi
next;
echo "----------------------------------------------------------------------------" &>> $LOG
step "     internet DNS ping"
log "Check that you can ping the an internet location"
	if ping -c 1 -i 0.5 www.google.com  &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
next;
echo "----------------------------------------------------------------------------" &>> $LOG
step "     rp_filter disabled"
logx sysctl -A | grep .rp_filter 
	if sysctl -A | grep -P '\.rp_filter' | grep -v -P '\.rp_filter.*=.*0' &>> $LOG   ; 
	then
		setfail
	else
		setpass
	fi
next;
echo "----------------------------------------------------------------------------" &>> $LOG
step "     check chronyd NTP"
logx chronyc tracking 
	if systemctl status chronyd | grep Active | grep running &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
next
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking LB Services Status"
log "Checking LB Process Status"
SERVICELIST="nst-loadbalancer nst-vip-manager jetty"
for SERVICE in $SERVICELIST
do
	step "     ${SERVICE}"
	logx systemctl status ${SERVICE}
	if systemctl status ${SERVICE} | grep -vP 'Active: active \(running\)' &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
	next;
done
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking Installed Packages"
PACKAGELIST="vim wget unzip expect nmap nmap nc net-tools net-snmp net-snmp-libs net-snmp-utils "
for PACKAGE in $PACKAGELIST
do
	step "     ${PACKAGE}"
	RESULT=$(yum -q list installed | grep ${PACKAGE} &>/dev/null &&  echo ${PACKAGE} is INSTALLED || echo ${PACKAGE} is NOT INSTALLED)
	if grep -q NOT <<<$RESULT; 
	then
		setfail
	else
		setpass
	fi
	next;
done
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
step "Checking JAVA version"
JAVAVER=$(`grep java /etc/sysconfig/nst-load* | awk -F"=" '/JAVA_EXE=(.*)/ {print $2;}'` -version 2>&1| grep version | awk '{print $NF}')
 	log $JAVAVER
	if grep -q 1.8 <<< $JAVAVER ;
	then
		BUILD=$(echo $JAVAVER | echo '"1.8.0_121"' | sed 's/"//g' | awk -F"_"  '{print $2}')
		if [ $BUILD -ge 90 ] ;
		then
			setpass
		else
			setfail
		fi
	else
		setfail
		echo -en "\033[70Gversion 1.8 required"
	fi
	next;

echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Gathering Additional Information"
step "    Basic System Information"
logx hostname
logx hostnamectl
logx cat /etc/system-release
logx cat /etc/redhat-release
logx sestatus
logx lscpu
logx free -ml
logx df -h
logx ip a
logx curl http://127.0.0.1:10080/system
logx cat /proc/meminfo

next

step "   Network Configuration"
logx ifconfig
logx ifconfig -a
logx ip a
logx netstat -anope
logx route
next

step "     Firewall Information"
logx iptables --list
logx firewall-cmd --list-all-zones
next

step "     System process and package information"
logx cat /etc/system-release
logx cat /etc/redhat-release
logx ps -Afe
logx rpm -qa 
logx yum history info
logx systemctl list-unit-files
logx chkconfig --list
logx crontab -l 
log cron tasks
cat /etc/passwd | sed 's/^\([^:]*\):.*$/crontab -u \1 -l 2>\&1/' | grep -v "no crontab for" | sh >> $LOG
next



step "     System usage and performance data"
logx uptime
logx top -b -n 1 
logx sar -A 
logx cat /proc/cpuinfo
logx lscpu
logx free -ml
logx cat /var/lib/xms/meters/currentValue.txt
next

step "     Other Misc Troubleshooting data"
logx env
for nic in `ls /sys/class/net` ; 
do 
logx ethtool --show-offload $nic; 
done 
logx lspci
logx sysctl -A 
logx dmidecode 
logx dmesg
logx ulimit -a
logx uname -a
next
echo


log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
step "Compressing system and LB information"
tar cvzf $OUTFILE --exclude='*.tgz' --exclude='*jetty*' $TMPPATH ./*.log ./*.sh ./*.pl /opt/nst-loadbalancer /var/log/messages*  /etc/hosts  /etc/fstab /etc/cluster/cluster.conf /etc/sysctl.conf /etc/sysconfig  &>/dev/null
next
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Audit complete, see $LOG for details"
logger -t SCRIPT  "Audit complete, see $LOG for details"
echo
