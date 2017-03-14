#!/bin/bash
# This script will install the packages that are needed for the lb
if [ -e "/etc/init.d/functions" ];
then
. /etc/init.d/functions
else
# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
OFFSET='\033[60G'
echo_success(){
  echo -en \\033
  echo -en "${OFFSET}${GREEN}[OK]${NC}";
}
echo_failure(){
echo -en "${OFFSET}${RED}[FAIL]${NC}";
}
fi
step() {
    echo -n -e "$@"
    echo -e "\n\nSTEP -  $@" >> $LOG
    STEP_OK=0
}
next() {
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo
    echo -e "STEP result">> $LOG
    echo -e "#########################################################################" >> $LOG
    return $STEP_OK
}
###########################################################################
#######                Start of script                             ########
###########################################################################
LOG="packageinstall.log"
starttime=`date +"%Y-%m-%d_%H-%M-%S"`

echo "Dependency Install started at ${starttime}" > $LOG
logger -t SCRIPT  "Installing LB Packages via $0"


echo "Basic Packages"

PACKAGELIST="vim wget unzip expect nmap abrt tcpdump omping sysstat"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	yum -y install $PACKAGE &>> $LOG
	next;
done

echo "LB Package Dependencies"
PACKAGELIST="nmap nc net-tools perl"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	yum -y install $PACKAGE &>> $LOG
	next;
done

echo "SNMP Packages"
PACKAGELIST="net-snmp net-snmp-libs net-snmp-utils"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	yum -y install $PACKAGE &>> $LOG
	next;
done

echo
step "Updating the kernel via yum"
yum -y update kernel &>> $LOG
next;

#step "Performing yum update"
#yum -y update &>> $LOG
#next;
echo
echo "Note- kernel update requires a system restart"
echo
echo "Process complete, see $LOG for details"
logger -t SCRIPT  "Install complete, see $LOG for details"

