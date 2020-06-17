#/bin/bash
<<TODO
    systemd et init.d
    filebeat depuis yum
    ram
    ip facultative
    vérification version package
    rsyslog serveur
    config beat pour rsyslog client et serveur
    usage: ./elk [type] [option] (type: elk, rsyslog, client)
TODO
version=0.7

usage="\
Options:
   --help       display this help and exit.
   --version    display version info and exit.

   --java11     use java 11 instead of Java 8 (default)

   --dissable-selinux

   --dissable-firewall

   -t type	client (default), server, clientServer (client for the server)

   --kibana IP PORT

   --elastic IP PORT

IP format IPv4 (or localhost)
NOTE/TODO: l'ip de kibana est automatiquement redéfinit sur l'ip de la machine du réseau local
"

info="\
Installs ELK 7  for centos 8
Script version: $version
"

#source function #import function

#Variable
package_java="1.8.0"
package_e="elasticsearch"
package_k="kibana"
package_l="logstash"
mem=1G
ipE=localhost #default restrict access to Kibana
ipk=localhost
portE=9200
portK=5601
portL=5044
type="client"
sel=0
firewall=0
p=yum
declare -i need=0
###############################################################################


#test command installed
if command -v dnf>/dev/null;then p=dnf; fi
if ! command -v systemctl>/dev/null;then c=service; fi
###############################################################################


#Function

#Source: https://docwhat.org/bash-checking-a-port-number    #
#############################################################
function to_int {                                           #
   local -i num="10#${1}"                                   #
   echo "${num}"                                            #
}                                                           #
                                                            #
function port_is_ok {                                       #
   local port="$1"                                          #
   local -i port_num=$(to_int "${port}" 2>/dev/null)        #

   if [ $port == "localhost" ];then
      return 0
   fi
                                                            #
   if (( $port_num < 1 || $port_num > 65535 )) ; then       #
      echo "*** ${port} is not a valid port" 1>&2           #
      return 1                                              #
   fi                                                       #
                                                            #
   return 0                                                 #
}                                                           #
#############################################################

function isinstalled {
   if ${com} list installed "$@" 1>/dev/null; then
      true
   else
      false
   fi
}

function isUpToDate {
   ${com} check-update "$@" 1>/dev/null
   if [ $? -eq 100 ];then
      true
   else
      false
   fi
}

function javaInstall {
   java_installed=$(${com} list installed java-*-openjdk 2>/dev/null | grep -E -o "java-[0-9.]*-openjdk")
   if [ $(echo $?) == "0" ]; then
      echo "Version $java_installed is installed, do you want to remove this version ?"
      while [[ $REP_JAVA != "y" && $REP_JAVA != "n" ]]; do
         read -rp "Remove $java_installed [y/n]: " -e REP_JAVA
      done
      if [ $REP_JAVA == "y" ]; then
         printf "\nRemove $java_installed\n"
         ${com} remove -y $java_installed
         printf "\nInstall java-"$@"-openjdk\n"
         ${com} install -y java-"$@"-openjdk
      else
	      printf "Keep $java_installed\n"
      fi
   else
      printf "\nInstall java-"$@"-openjdk\n"
      ${com} install -y java-"$@"-openjdk
   fi
}

function ip_is_ok {
   re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
   re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'

   if [[ $1 =~ $re ]]; then
      return 0
   else
      return 1
   fi
}
###############################################################################


#test run as root user
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit 1
fi

#arg
while test $# -ne 0; do
   case $1 in
      --help) echo "$usage"; exit $?;;

      --info) echo "$info"; exit $?;;

      --java11) package_java="11";;

      --dissable-selinux) sel=1;;

      --dissable-firewall) firewall=1;;

      --kibana)
         if ip_is_ok $2; then
            if port_is_ok $3; then
               ipK=$2
               portK=$3
            else
               exit 2
            fi
         else
            exit 2
         fi
         need=$need+1
      ;;

      --elastic)
         if ip_is_ok $2; then
            if port_is_ok $3; then
               ipE=$2
               portE=$3
            else
               exit 2
            fi
         else
            exit 2
         fi
         need=$need+1
      ;;

      -t)
	      if [ "$2" == "server" ]; then
		      type="server"
	      fi
      ;;
  esac
  shift
done

if [ $need -ne "2" ]; then
	echo -e  "\033[0;33m--elastic && --kibana\033[0m"
	exit 2
fi

#Security
if [ $sel -eq 1 ]; then
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
fi

if [ $firewall -eq 1 ]; then
	test=$(sudo systemctl is-enabled firewalld.service)
	if [ $test == "enabled" ] ; then
		systemctl disable firewalld
		systemctl stop firewalld
	fi
fi


#Server
if [ $type == "server" ];then

   #1. JAVA
   if isinstalled java-$package_java-openjdk; then
      echo "java-$package_java-openjdk already installed";
      if isUpToDate java-$package_java-openjdk; then
         ${com} update java-$package_java-openjdk
   else
      javaInstall $package_java
   fi


   #2 Elasticsearch 7
   if isinstalled $package_e; then
      echo "$package_e already installed"
      if isUpToDate $package_e; then ${com} $package_e; fi
   else
      printf "\nInstall $package_e\n"
      rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

      cat <<EOF | tee /etc/yum.repos.d/Elastic-elasticsearch.repo
[elasticstack]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

      ${p} -q check-update

      ${p} -y install $package_e

      printf "\nConfiguration\n"

      sed -i "s/#network.host: 192.168.0.1/network.host: $ipE/" /etc/elasticsearch/elasticsearch.yml
      sed -i "s/#http.port: 9200/http.port: $portE/" /etc/elasticsearch/elasticsearch.yml

      #ram
#      sed -i "s/^-Xms.*$/-Xms$mem/" /etc/elasticsearch/jvm.options
#      sed -i "s/^-Xmx.*$/-Xmx$mem/" /etc/elasticsearch/jvm.options

      systemctl daemon-reload
      systemctl enable --now elasticsearch.service

      #test if works
      printf "\nTest if Elasticsearch works (sleep 10s)\n"
      sleep 10
      if curl -XGET "localhost:9200" &>/dev/null;then echo -e "\033[0;32mElasticsearch work\033[0m"; else echo -e "\033[0;31mElasticsearch doesn't work\033[0m"; exit 3; fi
fi


   #3 Kibana
   if isinstalled $package_k; then
      echo "$package_k already installed"
      if isUpToDate $package_k; then ${com} $package_k; fi
   else
      ${p} -y install $package_k

      #kibana server port
      sed -i "s/#server.port: 5601/server.port: $portK/" /etc/kibana/kibana.yml

      #kibana server ip
#      ip=$(hostname -I | awk '{print $1}')
      local ip=$(hostname -i)
      sed -i "s/#server.host: \"localhost\"/server.host: $ip/" /etc/kibana/kibana.yml #TODO host donne l'accès: localhost=que le pc, 192.x.x.x donne accès à tous les machine qui on accès a cette ip

      #bind the kibana server to the local Elasticsearch server
      sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/' /etc/kibana/kibana.yml

      #allow external connection
      if [ $firewall -eq 0 ]; then
         firewall-cmd --add-port=$portK/tcp --permanent
         firewall-cmd --reload
      fi

      systemctl enable --now kibana

      printf "\nTest if Elasticsearch works (sleep 30s)\n"
      echo "sleep 30s"
      sleep 20s
      if curl -XGET "$ip:5601" &>/dev/null;then echo -e "\033[0;32mKibana work\033[0m"; else echo -e "\033[0;31mKibana doesn't work\033[0m"; exit 3 ; fi # //TODO remplacer localhost par l'ip voulu
   fi

   #Logstash

   if isinstalled $package_l; then
      echo "$package_l déjà installé"
      if isUpToDate $package_l; then ${com} $package_l; fi
   else
      ${p} -y install $package_l

      #allow external connection
      if [ $firewall -eq 0 ]; then
         firewall-cmd --add-port=$portL/tcp --permanent
         firewall-cmd --reload
      fi

      cat <<EOF | tee /etc/logstash/conf.d/elk.conf
input {
  beats {
    port => 5044
  }
}
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
  }
}
EOF

      systemctl daemon-reload
      systemctl enable --now logstash.service
   fi

elif [ $type == "client" ];then
   #1. filebeat
   if isinstalled $package_f; then
      echo "$package_f already installed";
      if isUpToDate $package_f; then ${com} $package_f; fi
   else
      cd /tmp
      curl -L -0 =https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.7.1-x86_64.rpm
      rpm -vi filebeat-7.7.1-x86_64.rpm
      rm -f filebeat-7.7.1-x86_64.rpm

      sed -i "s/hosts: [\"localhost:9200\"]/hosts: [\"$ipE:$portE\"]/" /etc/filebeat/filebeat.yml
      sed -i "s/#host: \"localhost:5601\"/host: \"$ipK:$portK\"/" /etc/filebeat/filebeat.yml

      filebeat setup -e --dashboards
   fi

   #2.rsyslog
   echo "*.* @$ipRsys" >>/etc/rsyslog.conf
   systemctl restart rsyslog
fi