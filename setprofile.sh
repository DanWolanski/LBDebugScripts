#! /bin/bash
# run with 
# . ./setprofile.sh ; echo $PATH
#get the current jdk verion
JAVADIR=$(ls /opt | grep --color=NEVER jdk)

echo "-----------------------------------------------------------"
echo Java directory detected as 
echo ${JAVADIR}

#update the profile.d to include a java_local.sh
cat <<__EOF > /etc/profile.d/java_local.sh 
# Adding current JDK binaries path 
PATH=$PATH:/opt/${JAVADIR}/bin:/opt/${JAVADIR}/jre/bin 
export PATH 
__EOF

#source the new profile
source /etc/profile
echo "-----------------------------------------------------------"
echo "New PATH is:"
echo $PATH

echo "-----------------------------------------------------------"
echo "Java Version is:"
java -version
echo "-----------------------------------------------------------"
