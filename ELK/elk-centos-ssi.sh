#/bin/bash
<<TODO
    systemd et init.d
    filebeat depuis yum
    ram
    vérification version package
    rsyslog serveur
    config beat pour rsyslog client et serveur
TODO

version=0.8

showHelp() {
cat <<EOF
./elk-centos [SETUP] [OPTIONS...]

Help:
   -h, --help		   display this help and exit.
   -v, --version	   display version info and exit.

Setup type:
   --elkserver		   install elk server
   --rsyserver 		   install rsyslog server
   --client                install client

Options:
   --portl=PORT		   set logstash input port [5044]
   --portk=PORT		   set kibana port [5601]
   --porte=PORT		   set elasticsearch port [9200]
   --portr=PORT		   set rsyslog port [514]
   --ipk=IPv4		   set kibana access ip ["local ip"]
   --ipe=IPv4		   set elasticsearch access ip [localhost]
   --ipr=IPv4		   set the rsyslog ip
   --systrans=PROTOCOL	   set protocol tranport (UDP|TCP) [UDP]
   --java11                use java 11 instead of Java 8
   --dissable-selinux      need reboot
   --dissable-firewall
EOF
exit 0
}

showInfo(){
cat <<EOF
Install ELK stack v7 for centos
Script version: $version
EOF
exit 0;
}
###############################################################################



#Variable
setT=false
type=
p=yum
declare -i need=0

javaVersion="1.8.0"
package_e="elasticsearch"
package_k="kibana"
package_l="logstash"

mem=1G
ipE=localhost #default restrict access to Kibana
ipK=localhost
ipR=
ipLocal=
declare -i portE=9200
declare -i portK=5601
declare -i portL=5044
declare -i portR=514
rProtocol=

disableSel=false
disableFirewall=false
###############################################################################




if command -v dnf>/dev/null;then p=dnf; fi #if dnf not exist, used yum
if ! command -v systemctl>/dev/null;then c=service; fi #TODOif systemd not exist, used init.d
ipLocal=$(hostname -i)
###############################################################################



#Function

#Source: https://docwhat.org/bash-checking-a-port-number
function to_int {
   local -i num="10#${1}"
   echo "${num}"
}

function port_is_ok {
   local port="$1"
   local -i port_num=$(to_int "${port}" 2>/dev/null)

   if (( $port_num < 1 || $port_num > 65535 )) ; then
      argErr "*** ${port} is not a valid port"
      return 1
   fi

   return 0
}


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
   javaInstalled=$(${com} list installed java-*-openjdk 2>/dev/null | grep -E -o "java-[0-9.]*-openjdk")
   if [ $(echo $?) == "0" ]; then
      echo "Version $javaInstalled is installed, do you want to remove this version ?"
      while [[ $REP_JAVA != "y" && $REP_JAVA != "n" ]]; do
         read -rp "Remove $javaInstalled [y/n]: " -e REP_JAVA
      done
      if [ $REP_JAVA == "y" ]; then
         printf "\nRemove $javaInstalled\n"
         ${com} remove -y $java_installed
         printf "\nInstall java-"$@"-openjdk\n"
         ${com} install -y java-"$@"-openjdk
      else
	      printf "Keep $javaInstalled\n"
      fi
   else
      printf "\nInstall java-"$@"-openjdk\n"
      ${com} install -y java-"$@"-openjdk
   fi
}

function ip_is_ok {
   re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
   re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'

   if [ "$1" == "localhost" ];then
      return 0
   fi

   if [[ $1 =~ $re ]]; then
      return 0
   else
      argErr "*** $1 is not a valid ip"
      return 1
   fi
}

setType(){
   if [ "$setT" = false ];then
      if [ "$1" = "--elkserver" ];then type="elkserver"; fi
      if [ "$1" = "--rsyserver" ];then type="rsyserver"; fi
      if [ "$1" = "--client" ];then type="client"; fi
      setT=true
   else
      >&2 echo "There can be only one type argument."
      echo "See $0 --help for used $1"
      exit 1
   fi

}

argErr(){
  echo "$1"
  exit 1
}
################################################################################



#arg
for opt do
   optval="${opt#*=}"
   case "$opt" in
      --dissable-firewall) disableFirewall=1
      ;;
      --dissable-selinux) disableSel=true
      ;;
      --elkserver|--rsyserver|--client) setType $opt
      ;;
      --help|-h) showHelp
      ;;
      --ipe=*) if ip_is_ok $optval;then ipE=$optval; fi
      ;;
      --ipk=*) if ip_is_ok $optval;then ipK=$optval; fi
      ;;
      --ipr=*) if ip_is_ok $optval;then ipR=$optval; fi
      ;;
      --java11) javaVersion="11"
      ;;
      --porte=*) if port_is_ok $optval;then portE=$optval; fi
      ;;
      --portk=*) if port_is_ok $optval;then portK=$optval; fi
      ;;
      --portl=*) if port_is_ok $optval;then portL=$optval; fi
      ;;
      --portr=*) if port_is_ok $optval;then portR=$optval; fi
      ;;
      --version|-v) showInfo
      ;;
      *)
         echo "Unknown option $1, ignored"
         ;;

  esac
done
echo $portL $portK $portE $javaVersion $ipE $ipK $ipR
exit 1000
#test run as root user
if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        exit 1
fi


if [ $need -ne "2" ]; then
	echo -e  "\033[0;33m--elastic && --kibana\033[0m"
	exit 2
fi

#Security
if $disableSel; then
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
fi

if $disableFirewall; then
	test=$(sudo systemctl is-enabled firewalld.service)
	if [ $test == "enabled" ] ; then
		systemctl disable firewalld
		systemctl stop firewalld
	fi
fi

#repo
printf "\nInstall repo Elastic 7.x\n"
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
#removeKey
#rpm -e $(rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n' | grep -oP '.*(?=gpg\(Elasticsearch)')
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

#Server
if [ $type == "server" ];then

   #1. JAVA
   if isinstalled java-$javaVersion-openjdk; then
      echo "java-$javaVersion-openjdk already installed";
      if isUpToDate java-$javaVersion-openjdk; then 
         ${com} update java-$javaVersion-openjdk; fi
   else
      javaInstall $javaVersion
   fi


   #2 Elasticsearch 7
   if isinstalled $package_e; then
      echo "$package_e already installed"
      if isUpToDate $package_e; then ${com} $package_e;  fi
   else
      printf "\nInstall $package_e\n"
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
      printf "\nInstall $package_k\n"
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
      if $disableFirewall; then
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
      printf "\nInstall $package_l\n"
      ${p} -y install $package_l

      #allow external connection
      if $disableFirewall; then
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
  }
}
EOF

      systemctl daemon-reload
      systemctl enable --now logstash.service
   fi

else
   #1. filebeat
   if isinstalled $package_f; then
      echo "$package_f already installed";
      if isUpToDate $package_f; then ${com} $package_f; fi
   else
      printf "\nInstall $package_f\n"
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
