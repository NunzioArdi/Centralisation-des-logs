#/bin/bash
<<TODO
    vérification version package
    rsyslog serveur
    config beat pour rsyslog client et serveur
    firewall sur init.d
TODO

version=0.8c

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
   --dissable-firewall
   --dissable-selinux      need reboot
   --ipe=IPv4		   set elasticsearch access ip [localhost]
   --ipk=IPv4		   set kibana access ip ["local ip"]
   --ipr=IPv4		   set the rsyslog ip
   --java11                use java 11 instead of Java 8
   --meme=STRING	   set Xmx and Xms for elasticsearch [2G]
   --memk=STRING           set Xmx and Xms for kibana [2G]
   --meml=STRING	   set Xmx and Xms for logstash [1G]
   --porte=PORT		   set elasticsearch port [9200]
   --portk=PORT		   set kibana port [5601]
   --portl=PORT		   set logstash input port [5044]
   --portr=PORT		   set rsyslog port [514]
   --systrans=PROTOCOL	   set protocol tranport (UDP|TCP) [UDP]
EOF
exit 0
}

showInfo(){
cat <<EOF
Install ELK stack v7 for centos
Support centos 7 and 8 (systemd)
Centos 6 (init.d) is planned to be supported
Script version: $version
EOF
exit 0;
}
################################################################################



#Variable
type=
p=yum
systemd=true

javaVersion="1.8.0"
package_e="elasticsearch"
package_k="kibana"
package_l="logstash"

memE=2G
memK=2G
memL=1G
ipE=localhost #default restrict access to Kibana
ipK=
ipR=
ipLocal=
declare -i portE=9200
declare -i portK=5601
declare -i portL=5044
declare -i portR=514
rProtocol="UDP"

disableSel=false
disableFirewall=false
################################################################################




if command -v dnf>/dev/null;then p=dnf; fi
if ! command -v systemctl>/dev/null;then systemd=false; fi
if hostname -I&>/dev/null; then ipLocal=$(hostname -I | awk '{print $1}');
   else ipLocal=$(hostname -i); fi
################################################################################



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
      argErr "${port} is not a valid port"
      return 1
   fi

   return 0
}


function isinstalled {
   if ${p} list installed "$@" 1>/dev/null; then
      true
   else
      false
   fi
}

function isUpToDate {
   ${p} check-update "$@" 1>/dev/null
   if [ $? -eq 100 ];then
      true
   else
      false
   fi
}

function javaInstall {
   javaInstalled=$(${p} list installed java-*-openjdk 2>/dev/null | grep \
      -E -o "java-[0-9.]*-openjdk")
   if [ $(echo $?) == "0" ]; then
      echo "Version $javaInstalled is installed, do you want to remove this version ?"
      while [[ $REP_JAVA != "y" && $REP_JAVA != "n" ]]; do
         read -rp "Remove $javaInstalled [y/n]: " -e REP_JAVA
      done
      if [ $REP_JAVA == "y" ]; then
         printf "\nRemove $javaInstalled\n"
         ${p} remove -y $java_installed
         printf "\nInstall java-"$@"-openjdk\n"
         ${p} install -y java-"$@"-openjdk
      else
	      printf "Keep $javaInstalled\n"
      fi
   else
      printf "\nInstall java-"$@"-openjdk\n"
      ${p} install -y java-"$@"-openjdk
   fi
}

ipIsOk(){
   local re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
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
   if [[ -z "$type" ]];then
      if [ "$1" == "--elkserver" ];then type="elkserver"; fi
      if [ "$1" == "--rsyserver" ];then type="rsyserver"; fi
      if [ "$1" == "--client" ];then type="client"; fi
   else
      >&2 echo "There can be only one type argument."
      echo "See $0 --help for used $1"
      exit 1
   fi
}

protocolIsOk(){
   if [ "$1" == "UDP"] || [ "$1" == "TCP" ];then
      return 0
   else
      argErr "$1 is not a valid protocol"
      return 1
   fi
}

memIsOk(){
   local re="\d*[gGmMkK]"

   if [[ $1 =~ $re ]]; then
      return 0
   else
      argErr "$1 is not a valid Xmx value"
      return 1
   fi

}

argErr(){
  echo -e "\033[0;33m*** $1\033[0m"
  exit 1
}
################################################################################



#arg
for opt in $@; do
   optX=$opt
   optval="${opt#*=}"
   case "$opt" in
      --client) setType $opt
      ;;
      --dissable-firewall) disableFirewall=1
      ;;
      --dissable-selinux) disableSel=true
      ;;
      --elkserver) setType $opt
      ;;
      --help|-h) showHelp
      ;;
      --ipe=*) if ipIsOk $optval;then ipE=$optval; fi
      ;;
      --ipk=*) if ipIsOk $optval;then ipK=$optval; fi
      ;;
      --ipr=*) if ipIsOk $optval;then ipR=$optval; fi
      ;;
      --java11) javaVersion="11"
      ;;
      --meme=*) if memIsOk $optval;then memE=$optval; fi
      ;;
      --memk=*) if memIsOk $optval;then memK=$optval; fi
      ;;
      --meml=*) if memIsOk $optval;then memL=$optval; fi
      ;;
      --porte=*) if port_is_ok $optval;then portE=$optval; fi
      ;;
      --portk=*) if port_is_ok $optval;then portK=$optval; fi
      ;;
      --portl=*) if port_is_ok $optval;then portL=$optval; fi
      ;;
      --portr=*) if port_is_ok $optval;then portR=$optval; fi
      ;;
      --rsyserver) setType $opt
      ;;
      --systrans=*) if protocolIsOk $optval; then rProtocol=$optval; fi
      ;;
      --version|-v) showInfo
      ;;
      *)
         echo "Unknown option $1, ignored"
         ;;
  esac
done

#test run as root user
if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        exit 1
fi

#check arg
if [[ -z "$type" ]]; then
	argErr "A type argument is missing"
fi

if [ "$type" == "client" ] && [ -z "$ipR" ];then
   argErr "--ipr must be specified for client type"
fi

if [ "$type" == "client" ] && [ -z "$ipK" ];then
   argErr "--ipk must be specified for client type"
fi

if [ "$type" == "server" ] && [ -z "$ipK" ];then
   ipK=$ipLocal
fi
################################################################################



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
################################################################################



#repo
#removeKey
#rpm -e $(rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'\
# | grep -oP '.*(?=gpg\(Elasticsearch)')
if ! rpm -q gpg-pubkey | grep 'gpg-pubkey-d88e42b4-52371eca'>/dev/null; then
   printf "\nInstall repo Elastic 7.x\n"
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
   ${p} -q check-update 1>/dev/null
else
   echo "The repo Elastic 7.x is already installed"
fi
################################################################################



#Server
if [ $type == "elkserver" ];then

   #1. JAVA
   if isinstalled java-$javaVersion-openjdk; then
      echo "java-$javaVersion-openjdk already installed";
      if isUpToDate java-$javaVersion-openjdk; then 
         ${p} update java-$javaVersion-openjdk; fi
   else
      javaInstall $javaVersion
   fi


   #Elasticsearch
   if isinstalled $package_e; then
      echo "$package_e already installed"
      if isUpToDate $package_e; then ${p} $package_e;  fi
   else
      printf "\nInstall $package_e\n"
      ${p} -y install $package_e

      printf "\nConfiguration\n"

      sed -i "s/#network.host: 192.168.0.1/network.host: $ipE/" /etc/elasticsearch/elasticsearch.yml
      sed -i "s/#http.port: 9200/http.port: $portE/" /etc/elasticsearch/elasticsearch.yml

      #ram
      sed -i "s/^-Xms.*$/-Xms$memE/" /etc/elasticsearch/jvm.options
      sed -i "s/^-Xmx.*$/-Xmx$memE/" /etc/elasticsearch/jvm.options

      if $systemd; then
         systemctl daemon-reload
         systemctl enable --now elasticsearch.service
      else
         service elasticsearch start
      fi

      #test if works
      printf "\nTest if Elasticsearch works (sleep 10s)\n"
      sleep 10
      if curl -XGET "localhost:9200" &>/dev/null;then echo -e "\033[0;32mElasticsearch work\033[0m"; else echo -e "\033[0;31mElasticsearch doesn't work\033[0m"; exit 3; fi
fi


   #Kibana
   if isinstalled $package_k; then
      echo "$package_k already installed"
      if isUpToDate $package_k; then ${p} $package_k; fi
   else
      printf "\nInstall $package_k\n"
      ${p} -y install $package_k

      printf "\nConfiguration\n"

      #kibana server port
      sed -i "s/#server.port: 5601/server.port: $portK/" /etc/kibana/kibana.yml

      #kibana server ip
      if [[ -z "$ipK" ]]; then
         ipK=$ipLocal
      fi
      sed -i "s/#server.host: \"localhost\"/server.host: $ipK/" /etc/kibana/kibana.yml #host donne l'accès: localhost=que le pc, 192.x.x.x donne accès à tous les machine qui on accès a cette ip

      #bind the kibana server to the local Elasticsearch server
      sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/' /etc/kibana/kibana.yml

      #allow external connection
      if $disableFirewall; then
         firewall-cmd --add-port=$portK/tcp --permanent
         firewall-cmd --reload
      fi

      if $systemd; then
         systemctl daemon-reload
         systemctl enable --now kibana
      else
         service kibana start
      fi

      printf "\nTest if Kibana works (sleep 25s)\n"
      sleep 25s
      if curl -XGET "$ipK:$portK" &>/dev/null;then echo -e "\033[0;32mKibana work\033[0m"; else echo -e "\033[0;31mKibana doesn't work\033[0m"; exit 3 ; fi
   fi

   #Logstash
   if isinstalled $package_l; then
      echo "$package_l already installed"
      if isUpToDate $package_l; then ${p} $package_l; fi
   else
      printf "\nInstall $package_l\n"
      ${p} -y install $package_l

      printf "\nConfiguration\n"

      #allow external connection
      if $disableFirewall; then
         firewall-cmd --add-port=$portL/tcp --permanent
         firewall-cmd --reload
      fi

      cat <<EOF | tee /etc/logstash/conf.d/elk.conf
input {
  beats {
    port => $ipL
  }
}
output {
  elasticsearch {
    hosts => ["$ipE:$portE"]
  }
}
EOF

      if $systemd; then
         systemctl daemon-reload
         systemctl enable --now logstash.service
      else
         service logstash start
      fi
   fi

else
   #1. filebeat
   if isinstalled $package_f; then
      echo "$package_f already installed";
      if isUpToDate $package_f; then ${p} $package_f; fi
   else
      printf "\nInstall $package_f\n"
      #cd /tmp
      #curl -L -0 =https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.7.1-x86_64.rpm
      #rpm -vi filebeat-7.7.1-x86_64.rpm
      #rm -f filebeat-7.7.1-x86_64.rpm

      ${p} -y install filebeat

      sed -i "s/hosts: [\"localhost:9200\"]/hosts: [\"$ipE:$portE\"]/" /etc/filebeat/filebeat.yml
      sed -i "s/#host: \"localhost:5601\"/host: \"$ipK:$portK\"/" /etc/filebeat/filebeat.yml

      filebeat setup -e --dashboards
   fi
fi

if [ "$type" == "client" ];then
   #rsyslog
   mv /etc/rsyslog.conf /etc/rsyslog.conf.back
   val=
   if [ "$rProtocol" == "UDP" ]; then val='@'; else val='@@'; fi
   echo "*.* $val$ipRsys" >>/etc/rsyslog.conf

   if $systemd; then
      systemctl restart rsyslog
   else
      service rsyslog restart
   fi
fi
