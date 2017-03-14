#!/bin/bash
# This script will add the iptables rule for udp
#   it will also setup so it is run each time at start 
#   by placing them in the /etc/iptables/rules.v4
STARTPWD=$(pwd)
LOG=${STARTPWD}/lbsysinit.log
echo "Starting LBSystemInit" > $LOG
logger -t "lbsysinit.sh" "Starting LB System Initilization via lbsysinit.sh script"
EXITONFAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
OFFSET='\033[60G'
echo_success(){
  echo -en \\033
  echo -en "${OFFSET}[  ${GREEN}OK${NC}  ]\n";
}
echo_failure(){
echo -en "${OFFSET}[${RED}FAILED${NC}]\n";
}
step() {
	echo "==========================================================================================="
	echo "====   $@"
	echo "==========================================================================================="
    echo -n -e "$@"
}
try (){
    "$@" &>> $LOG 
    if [[ $? -ne 0 ]] ; then 
	echo_failure  
     else 
	echo_success 
     fi
}

echo
step "Installing wget and unzip" 
try yum -y install wget unzip

step "Fetching LBDebugScripts Package"
try wget https://github.com/DanWolanski/LBDebugScripts/archive/master.zip

step "Unzipping Package"
try unzip master.zip

step "Entering Script Directory"
try cd LBDebugScripts-master
 
step "Setting scripts to executable"
try chmod +x *.sh

step "Disabling ipv6 (disableipv6.sh)"
try ./disableipv6.sh

step "Disabling firewall (disablefirewall.sh)"
try ./disablefirewall.sh

step "Disabling messages rate limiting (disableratelimiting.sh)"
try ./disableratelimiting.sh


step "Disabling rp_filter (disablerpfilter.sh)"
 try ./disablerpfilter.sh

step  "Disabling selinux (disableselinux.sh)"
try ./disableselinux.sh
 
step  "Adding udp iptables rule (setudprules.sh)"
try ./setudprules.sh

step "updating hosts file (sethosts.sh)"
try ./sethosts.sh

step "Installing Required Packages (installreqpackages.sh)"
try ./installreqpackages.sh
cat packageinstall.log >> $LOG

step "Performing yum update (yum update)"
try yum -y update

step "Getting latest jdk (getjdk.sh)"
try ./getjdk.sh

step "Updating profile (setprofile.sh)"
try . ./setprofile.sh

cd ${STARTPWD}

logger -t "lbsysinit.sh" "lbsysinit.sh script Initilization complete. see ${LOG} for details"

echo
echo "Process Complete!!
echo "  see ${LOG} for more details"
echo -e "${RED}Please Reboot before installing the LB Package${NC}"
echo

