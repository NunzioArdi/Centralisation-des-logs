#/bin/bash

#old version ti new rm -rf /var/liv/filebeat/

version=0.5

usage="\
Options:
   --help          display this help and exit.
   --version       display version info and exit.

--java11           use java 11 instead of Java 8 (default)
--kibana IP PORT
--elastic IP PORT  no logstash
"

info="\
Installs Client filebeat 7.7 for ELK for centos 8
Script version: $version
"

source function #import function


package_java="1.8.0"
package_f="filebeat"

ipE=0
portE=0
ipK=0
portK=0

#test run as root user
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit 1
fi


while test $# -ne 0; do
  case $1 in
    --help) echo "$usage"; exit $?;;

    --info) echo "$info"; exit $?;;

    --java11) package_java="11";;
    
    --kibana) 
            if [[ ip_is_ok $1 ]]; then
                if [[ port_is_ok $2 ]]; then
                    ipK=$1
                    portK=$2
                else
                    exit 1
                fi
            else
                exit 1
            fi;;
    --elcatic)
            if [[ ip_is_ok $1 ]]; then
                if [[ port_is_ok $2 ]]; then
                    ipE=$1
                    portE=$2
                else
                    exit 1
                fi
            else
                exit 1
            fi;;
               

  esac
  shif


#1. JAVA
if isinstalled java-$package_java-openjdk; then
    echo "java-$package_java-openjdk already installed";
else
     javaInstall $package_java
fi


#2. filebeat
if isinstalled $package_java; then 
    echo "$package_java déjà installé"; 
else 
     cd /tmp
     curl -L -0 =https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.7.1-x86_64.rpm
     rpm -vi filebeat-7.7.1-x86_64.rpm
     
     sed -i "s/hosts: [\"localhost:9200\"]/hosts: [\"$ipE:$portE\"]/" /etc/filebeat/filebeat.yml
     sed -i "s/#host: \"localhost:5601\"/host: \"$ipK:$portK\"/" /etc/filebeat/filebeat.yml

fi
