#/bin/bash

#old version ti new rm -rf /var/liv/filebeat/

version=0.6

usage="\
Options:
   --help          display this help and exit.
   --version       display version info and exit.

--kibana IP PORT
--elastic IP PORT

IP format IPv4
"

info="\
Installs Client filebeat 7.7 for ELK for centos 8
Script version: $version
"

source ./function #import function

package_f="filebeat"

ipE=0
portE=0
ipK=0
portK=0

need=0

#test run as root user
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit 1
fi


while test $# -ne 0; do
  case $1 in
    --help) echo "$usage"; exit $?;;

    --info) echo "$info"; exit $?;;

    --kibana)
            if ip_is_ok $2; then
                if port_is_ok $3; then
                    ipK=$2
                    portK=$3
                else
		    echo -e "\033[0;31mPort kibana: invalid format\033[0m"
                    exit 1
                fi
            else
		echo -e "\033[0;31mIp kibana: invalid format\033[0m"
                exit 1
            fi
	    need=$need+1;;
    --elastic)
		echo $2
		echo $3
            if ip_is_ok $2; then
                if port_is_ok $3; then
                    ipE=$2
                    portE=$3
                else
		    echo -e "\033[0;31mPort Elastic: invalid format\033[0m"
                    exit 1
                fi
            else
		    echo -e "\033[0;31mIp Elastic: invalid format\033[0m"
                exit 1
            fi
	    need=$need+1;;

  esac
  shift
done

#0.
if [ $need -ne "2" ]; then
	echo -e  "\033[0;33m--elastic && --kibana\033[0m"
	exit 2
fi

#1. filebeat
if isinstalled $package_f; then
    echo "$package_f déjà installé";
else
     cd /tmp
     curl -L -0 =https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.7.1-x86_64.rpm
     rpm -vi filebeat-7.7.1-x86_64.rpm

     sed -i "s/hosts: [\"localhost:9200\"]/hosts: [\"$ipE:$portE\"]/" /etc/filebeat/filebeat.yml
     sed -i "s/#host: \"localhost:5601\"/host: \"$ipK:$portK\"/" /etc/filebeat/filebeat.yml
     
     filebeat setup -e --dashboards 

fi
