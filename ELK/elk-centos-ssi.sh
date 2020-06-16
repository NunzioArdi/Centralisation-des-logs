#/bin/bash
##TODO config intéractive, ip et mem, verifier version

version=0.5

usage="\
Options:
   --help       display this help and exit.
   --version    display version info and exit.

   --java11     use java 11 instead of Java 8 (default)

   --dissable-selinux

   --dissable-firewall

   -t type	client (default), server, clientServer (client for the server)

   
"

info="\
Installs ELK 7.7 for centos 8
Script version: $version
"

source function #import function


package_java="1.8.0"
package_e="elasticsearch"
package_k="kibana"
package_l="logstash"
mem=1G
ipE=localhost #unused
ipk=localhost #unused
portE=9200    #unused
portK=5601
portL=5044    #unused
REP_PORT_VALID=1
REP_BOOT_VALID=1
type="client"
sel=0
firewall=0

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

    --dissable-selinux) sel=1;;

    --dissable-firewall) firewall=1;;

    -t)
	    if [ "$2" == "server" ]; then
		    type="server"
	    fi;; 
  esac
  shift
done


#0.

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


#1. JAVA
if isinstalled java-$package_java-openjdk; then
    echo "java-$package_java-openjdk already installed";
else
     javaInstall $package_java
fi


#2 Elasticsearch 7
if isinstalled $package_e; then
    echo "$package_e already installed"

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

    dnf -y update

    yum -y install $package_e

    printf "\nConfiguration\n"

    sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml #restrict access to Kibana
    sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
    
    #ram
#    sed -i "s/^-Xms.*$/-Xms$mem/" /etc/elasticsearch/jvm.options
#    sed -i "s/^-Xmx.*$/-Xmx$mem/" /etc/elasticsearch/jvm.options
    
    systemctl daemon-reload
    systemctl enable --now elasticsearch.service

    #test if works
    if curl -XGET "localhost:9200" &>/dev/null;then echo -e "\033[0;32mElasticsearch work\033[0m"; else echo -e "\033[0;33mElasticsearch doesn't work\033[0m"; exit 1; fi
fi


#3 Kibana
if isinstalled $package_k; then
    echo "$package_k already installed"
else
    yum -y install $package_k

    #kibana server port
    while [[ $REP_PORT_VALID != 0  ]]; do
        read -rp "Select external access port for Kabana [Default value: 5061]: " -e REP_PORT_TMP
                  : ${REP_PORT_TMP:=$portK}
        if port_is_ok $REP_PORT_TMP; then
          REP_PORT_VALID=0
          portK=$REP_PORT_TMP
        fi
    done
    sed -i "s/#server.port: 5601/server.port: $portK/" /etc/kibana/kibana.yml

    #kibana server ip
    ip=$(hostname -I | awk '{print $1}')
    sed -i "s/#server.host: \"localhost\"/server.host: $ip/" /etc/kibana/kibana.yml #TODO host donne l'accès: localhost=que le pc, 192.x.x.x donne accès à tous les machine qui on accès a cette ip

    #bind the kibana server to the Elasticsearch server
    sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/' /etc/kibana/kibana.yml

    #allow external connection
#    firewall-cmd --add-port=$portK/tcp --permanent
#    firewall-cmd --reload

    systemctl enable --now kibana

    echo "sleep 20s"
    sleep 20s
    if curl -XGET "$ip:5601" &>/dev/null;then echo -e "\033[0;32mKibana work\033[0m"; else echo -e "\033[0;31mKibana doesn't work\033[0m"; exit 1 ; fi # //TODO remplacer localhost par l'ip voulu 
fi


#Logstash

if isinstalled $package_l; then
    echo "$package_l déjà installé"
else
    yum -y install $package_l

    systemctl daemon-reload
    systemctl enable --now logstash.service

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
#    chown --recursive logstash /var/log/logstash
#    chown --recursive logstash /var/liv/logstash
#    chmod -R 755 /usr/share/logstash
#    chmod -R 755 /var/lib/logstash
fi
