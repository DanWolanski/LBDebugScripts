#!/bin/bash
# This script will download and compile the tmate app for Centos7
# Tmate is an opensource fork of tmux that allows for remote
# connections to the shell via ssh
#  you can find more details on 
#    https://tmate.io or https://github.com/tmate-io/tmate
# 
OLDPWD=$(pwd)
LOG=${OLDPWD}/gettmate.log
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

echo "Installing dependant Packages"
PACKAGELIST="git epel-release cmake ruby zlib-devel openssl-devel libevent-devel ncurses-devel libutempter-devel msgpack libssh-devel"
for PACKAGE in $PACKAGELIST
do
	step "    Installing $PACKAGE"
	try yum -y install $PACKAGE 
done

step "Installing Development Tools group"
 try yum -y group install "Development Tools"

step "Cloning tmate github repo "
if [ -d "/var/tmp" ]; then 
cd /var/tmp 
fi
try git clone https://github.com/nviennot/tmate.git &>> $LOG


cd tmate/
step "Autogenerating config"
try ./autogen.sh

step "Configuring source"
try ./configure 


step "Compiling tmate"
try make

step "Copying tmate exe to /usr/bin"
try cp tmate /usr/bin
cd $OLDPWD
 
echo
echo "Process Complete! See $LOG for details"

