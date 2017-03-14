#!/bin/bash
# This script will add the iptables rule for udp
#   it will also setup so it is run each time at start 
#   by placing them in the /etc/iptables/rules.v4
LOG=lbsysinit.log
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

step "Disabling ipv6"
try ./disableipv6.sh

step "Disabling firewall"
try ./disablefirewall.sh

step "Disabling messages rate limiting"
try ./disableratelimiting.sh


step "Disabling rp_filter"
 try ./disablerpfilter.sh

step  "Disabling selinux"
try ./disableselinux.sh

step  "Adding udp iptables rule"
try ./setudprules.sh

step "updating hosts file"
try ./sethosts.sh

step "Installing Required Packages"
try ./installreqpackages.sh
cat packageinstall.log >> $LOG

step "Performing yum update"
try yum -y update

step "Getting latest jdk"
try ./getjdk.sh

step "Updating profile"
try . ./setprofile.sh


logger -t "lbsysinit.sh" "lbsysinit.sh script Initilization complete"
echo
echo "Process Complete, see ${LOG} for more details"
echo -e "${RED}Please Reboot before installing the LB Package${NC}"
echo

