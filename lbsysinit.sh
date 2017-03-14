#!/bin/bash
# This script will add the iptables rule for udp
#   it will also setup so it is run each time at start 
#   by placing them in the /etc/iptables/rules.v4
LOG=/dev/null
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

echo
echo "Disabling ipv6"
./disableipv6.sh

echo
echo "Disabling firewall"
./disablefirewall.sh

echo
echo "Disabling messages rate limiting"
./disableratelimiting.sh

echo "---------------------------------------------------------------"
echo "Disabling rp_filter"
 ./disablerpfilter.sh

echo "Disabling selinux"
./disableselinux.sh

echo "Adding udp iptables rule"
./setudprules.sh

echo "updating hosts file"
./sethosts.sh

echo "Installing Required Packages"
./installreqpackages.sh

echo "Performing yum update"
yum -y update

echo "Getting latest jdk"
./getjdk.sh

echo "Updating profile"
. ./setprofile.sh

echo
echo "Process Complete"
echo -e "${RED} Please Reboot before installing the LB Package${NC}"
echo

