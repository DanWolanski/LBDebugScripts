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
    STEP_NAME="$@"
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
PASSLIST=""
PASSCOUNT=0
setpass(){
	PASSLIST="$PASSLIST\n${STEP_NAME}"
	let PASSCOUNT=PASSCOUNT+1
	STEP_OK=0
}
FAILLIST=""
FAILCOUNT=0
setfail(){
	FAILLIST="${FAILLIST}\n${STEP_NAME}"
	let FAILCOUNT=FAILCOUNT+1
	STEP_OK=1
}

###########################################################################
#######                Start of script                             ########
###########################################################################
hostname=`hostname -s`
OUTFILE="lbaudit_${hostname}.tgz"
LOG="lbaudit_${hostname}.log"
SUMMERYLOG="lbaudit-summery_${hostname}.log"
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
step "     check NTP enabled/synchronized"
logx timedatectl
	NTPENB=$(timedatectl | awk '/NTP enabled:/ {print $NF} ')
	NTPSYNC=$(timedatectl | awk '/NTP synchronized:/ {print $NF} ')
	NTPCHECK="${NTPENB}${NTPSYNC}";
	if grep -q 'yesyes' <<<$NTPCHECK; 
	then
		setpass
	else
		echo -en "\033[70GEnabled=${NTPENB} Synchronized=${NTPSYNC}"
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     check chronyd status"
logx chronyc tracking 
	if systemctl status chronyd | grep Active | grep running &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     timezone settings"
logx ls -al /etc/localtime
	if systemctl status chronyd | grep Active | grep running &>> $LOG ; 
	then
		setpass
	else
		setfail
	fi
next
echo "----------------------------------------------------------------------------" &>> $LOG
step "     UDP iptables rule"
logx iptables --list -t raw
	if iptables --list -t raw | grep -q -P "CT.*udp.*CT.notrack" &>> $LOG ;
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
echo "Checking Firewall settings"
step "     firewalld disabled"
	logx systemctl status firewalld
	if systemctl status firewalld | grep -vP 'Active: inactive' &>> $LOG ; 
	then
		setpass
	else
		logx systemctl
		echo -en "\033[70GEnabled-manually confirm exclusions"
		setfail
	fi
	next;
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking Network settings"
	logx ip a
	IPADDRS=$(ip addr show | perl -n -e '/inet (.*)\// && print "$1 "') 
	ADDRCOUNT=$(echo ${IPADDRS} | wc  -w );
	INTERFACELIST=$(ip addr show | perl -n -e '/.*: (.*?):.*qdisc/ && print "$1 "')
	INTERFACECOUNT=$(echo ${INTERFACELIST} | wc  -w );
	step "     interfaces count >2"
	if [ ${INTERFACECOUNT} -ge 2 ]
	then
		setpass
	else
		setfail
		echo -en "\033[70G$INTERFACECOUNT interfaces found"
	fi 
	next;
	step "     ipv4 address count >2"
	if [ ${ADDRCOUNT} -ge 2 ]
	then
		setpass
	else
		setfail
		echo -en "\033[70G$ADDRCOUNT ip addr found"
	fi 
	next;
echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking Installed Packages"
PACKAGELIST="vim wget unzip expect nmap nc abrt tcpdump perl net-tools net-snmp net-snmp-libs net-snmp-utils "
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
echo "CHecking JAVA Installation"
step "    JAVA version"
	if [ -e /etc/sysconfig/nst-loadbalancer.properties ];
	then
		JAVAVER=$(`grep java /etc/sysconfig/nst-loadbalancer.properties | awk -F"=" '/JAVA_EXE=(.*)/ {print $2;}'` -version 2>&1| grep version | awk '{print $NF}')
	else
		JAVAVER=$(ls /opt | awk '/j(dk|re)/')
	fi
 	log $JAVAVER
	if grep -q 1.8 <<< $JAVAVER ; then setpass; else setfail; echo -en "\033[70Gversion 1.8 required"; fi
	next;

step "     JAVA build"
	BUILD=$(echo $JAVAVER  | sed 's/"//g' | awk -F"_"  '{print $2}')
	if [ $BUILD -ge 90 ] ; then setpass; else setfail; fi

echo
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Checking LB OS Services Status"
log "Checking LB OS Process Status"
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
echo "Checking LB Properties Configuration"
	PROPFILE='/etc/sysconfig/nst-loadbalancer.properties'
	step "     Finding Properties file "
	logx cat ${PROPFILE}
	[ -e ${PROPFILE} ] && setpass || setfail ;
	next
	step "     Checking Install Path "
	LBDIR=$(awk -F"=" '/INSTALL_DIR/ {print $2}' $PROPFILE)
	[ -d ${LBDIR} ] && setpass || setfail ;
	next
	step "     Checking Java Path"
	JAVAEXE=$(awk -F"=" '/JAVA_EXE/ {print $2}' $PROPFILE)
	[ -e ${JAVAEXE} ] && setpass || setfail ;
	next
	step "     Checking ClusterID "
	CLUSTERID=$(awk -F"=" '/clusterId/ {print $2}' $PROPFILE)
	[ $CLUSTERID != '' ] && setpass || setfail ;
	next
	step "     Checking JMX Hostname "
	JMXHOST=$(awk -F"=" '/jmxHostname/ {print $2}' $PROPFILE)
	if grep -q $JMXHOST <<<$IPADDRS ; then setpass ; else setfail ;fi
	next
	step "     Checking JMX PORT"
	JMXPORT=$(awk -F"=" '/jmxRemotePort/ {print $2}' $PROPFILE)
	if netstat -aneop | grep -q ${JMXPORT}   ; then setpass; else setfail ;fi
	next
echo
echo "Checking LB VIP-Manager Properties Configuration"
	VIPPROPFILE='/etc/sysconfig/nst-vip-manager.properties'
	step "     Finding Vip-manager Properties file "
	logx cat ${VIPPROPFILE}
	[ -e ${VIPPROPFILE} ] && setpass || setfail ;
	next
	step "     Checking Vip-manager Java Path"
	VIPJAVAEXE=$(awk -F"=" '/JAVA_EXE/ {print $2}' $VIPPROPFILE)
	[ -e ${VIPJAVAEXE} ] && setpass || setfail ;
	next
	step "     Checking Vip-manager JMX Hostname "
	VIPJMXHOST=$(awk -F"=" '/jgroupsBindAddress/ {print $2}' $VIPPROPFILE)
	if grep -q $VIPJMXHOST <<<$IPADDRS ; then setpass ; else setfail ;fi
	next
	step "     Checking Vip-manager JMX PORT"
	VIPJMXPORT=$(awk -F"=" '/jmxRemotePort/ {print $2}' $VIPPROPFILE)
	if netstat -aneop | grep -q ${VIPJMXPORT}   ; then setpass; else setfail ;fi
	next
echo
echo "Checking LB Bootstrap Config"
	BSCFG="${LBDIR}/nst-bootstrap-config.xml"
	step "     finding bootstrap config "
	[ -e ${LBDIR} ] && setpass || setfail ;
	next
	\cp -f ${BSCFG} ./copy-nst-bootstrap-config.xml
	BSCFG="./copy-nst-bootstrap-config.xml"
	sed -i 's/xmlns=".*"/ /g' $BSCFG
	step "     checking hostname ip is on system"
	XMLHOSTNAME=$(xmllint --xpath '/nst-bootstrap/config/hostname/text()' ${BSCFG})
	if grep -q $XMLHOSTNAME <<<$IPADDRS ; then setpass; else setfail ;fi
	next
	step "     checking Local JMX bind address"
	XMLJMXBIND=$(xmllint --xpath '/nst-bootstrap/config/jmx-bind-address/text()' ${BSCFG})
	XMLJMXBINDHOST=$(echo $XMLJMXBIND | awk -F":" '{print $1}')
	XMLJMXBINDPORT=$(echo $XMLJMXBIND | awk -F":" '{print $2}')
	#TODO - This is better test but seems to take a long time so substituting for simple netstat
	#STATE=$(nmap -O ${XMLJMXBINDHOST} -p ${XMLJMXBINDPORT} -sS 2> /dev/null | awk '/\/tcp/ {print $2}'  )
	#if grep -q "open"<<<$STATE ; then setpass; else setfail ;fi
	if netstat -aneop | grep -q ${XMLJMXBINDPORT}   ; then setpass; else setfail ;fi
	next
	step "     checking Remote JMX host "
	XMLPAIRHOST=$(xmllint --xpath '/nst-bootstrap/config/paired-bootstrap-hostname/text()' ${BSCFG})
	XMLPAIRPORT=$(xmllint --xpath '/nst-bootstrap/config/paired-bootstrap-jmx-port/text()' ${BSCFG})
	STATE=$(nmap -O ${XMLPAIRHOST} -p ${XMLPAIRPORT} -sS 2> /dev/null | awk '/\/tcp/ {print $2}' )
	if grep -q "open"<<<$STATE ; then setpass; else setfail ;fi
	next
	step "     checking Interfaces are present"
	XMSINTERFACES=$(grep -P '<interface>' ${BSCFG} | awk -F"<|>" '{print $3}' | uniq)
	FOUNDBAD=0
	for INTERFACE in $XMSINTERFACES 
	do
		if grep -q $INTERFACE <<<$INTERFACELIST; then echo $INTERFACE OK &>>$LOG ; else let FOUNDBAD=FOUNDBAD+1 ; fi
	done
	next

echo "Checking Jetty Configuration"
	LBWEB='http://127.0.0.1:8888/lb/Login.jsf'
	LBWEBFAILSEARCH='(errorMessage|Connection refusted)'
	
	#TODO , search the actual config to find what interface
	step "     Checking localhost address "
	if ping -c 1 -i 0.5 localhost   &>> $LOG; then setpass; else setfail; fi
	next
	step "     Checking Jetty PORT"
	JETTYPORT='8888'
	if netstat -aneop | grep -q ${JETTYPORT}   ; then setpass; else setfail ;fi
	next
	step "     Checking Web Connectivity"
	if curl -vs http://127.0.0.1:8888/lb/Login.jsf 2>&1 | grep -P &> /dev/null'(Lost connection|Connection refused)';
	then setfail; else setpass; fi
	next

echo "Checking LB Configured Services"
	#TODO Auto Parse to find what is configured
	SERVICEDIRS="p1 p2 p3 p4 p5 p6 p7 p8 p9 p10"
	for SERVICEDIR in  $SERVICEDIRS;
		do
		
		if [ -d "$LBDIR/$SERVICEDIR" ]; then
		SNAME=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/name/text()' -) ;
		SLOCALADDRA=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/local-address-A/text()' -) ;
		SLOCALADDRB=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/local-address-B/text()' -) ;
		SPORT=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/servicePort/text()' -) ;
		SJMXADDR=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/jmx-bind-address/text()' - | awk -F":" '{print $1}') ;
		SJMXPORT=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/jmx-bind-address/text()' - | awk -F":" '{print $2}') ;
		SJMXREMOTEADDR=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/other-jmx-address/text()' -  | awk -F":" '{print $1}') ;
		SJMXREMOTEPORT=$(cat ${LBDIR}/${SERVICEDIR}/nst-lb-config.xml |  sed  's/xmlns=".*"/ /g' | xmllint --xpath '/nst-lb/config/other-jmx-address/text()' - | awk -F":" '{print $2}') ;
		echo "  -${SNAME}"
		step "     Service Port"
		if netstat -aneop | grep -q ${SPORT}   ; then setpass; else setfail ;fi
		next
		step "     Inbound Vip"
		if grep -q $SLOCALADDRA <<<$IPADDRS ; then setpass; else setfail ;fi
		next
		#TODO Not all protocols have outbounds. 
		#step "     Outbound Vip"
		#if grep -q $SLOCALADDRB <<<$IPADDRS ; then setpass; else setfail ;fi
		#next
		step "     Local JMX"
		#STATE=$(nmap -O ${SJMXADDR} -p ${SJMXPORT} -sS 2> /dev/null | awk '/\/tcp/ {print $2}' )
		#if grep -q "open"<<<$STATE ; then setpass; else setfail ;fi
		if netstat -aneop | grep -q ${SJMXPORT}   ; then setpass; else setfail ;fi
		next
		step "     Remote JMX"
		STATE=$(nmap -O ${SJMXREMOTEADDR} -p ${SJMXREMOTEPORT} -sS 2> /dev/null | awk '/\/tcp/ {print $2}' )
		if grep -q "open"<<<$STATE ; then setpass; else setfail ;fi
		next
		#TODO Using Test Script to test service.
		#step "     Testing Service"
		#if grep -q "open"<<<$STATE ; then setpass; else setfail ;fi
		#next
		fi
	done
	
	

echo

log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Gathering Additional Information"
step "     Basic System Information"
logx hostname
logx hostnamectl
logx cat /etc/system-release
logx cat /etc/redhat-release
logx sestatus
logx lscpu
logx free -ml
logx df -h
logx ip a
logx cat /proc/meminfo
logx timedatectl
next

step "     Network Configuration"
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
echo -e "Audit of ${hostname} @ $starttime \n${PASSCOUNT} Passed:\n${PASSLIST}\n${FAILCOUNT} Failed:\n${FAILLIST}" > ${SUMMERYLOG}
cat ${SUMMERYLOG} >> $LOG
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
echo "Audit complete! "
echo -e "   ${GREEN}$PASSCOUNT checks Passed${NC}"
echo -e "   ${RED}$FAILCOUNT checks Failed${NC}"
echo "Results saved to $SUMMERYLOG, "
echo "   see $LOG for full details"
logger -t SCRIPT  "Audit complete $PASSCOUNT Passed, $FAILCOUNT Failed, See $LOG for details"
echo
