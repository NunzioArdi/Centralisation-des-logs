#/bin/bash
##TODO config intéractive, ip et mem, verifier version

version=0.3

usage="\
Options:
   --help       display this help and exit.
   --version    display version info and exit.

   --java11      use java 11 instead of Java 8 (default)
"

info="\
Installs ELK 7.7 for centos 8
Script version: $version
"

function isinstalled {
  if yum list installed "$@" 1>/dev/null 2>&1; then
    true
  else
    false
  fi
}

function javaInstall {
    java_installed=$(yum list installed java-*-openjdk 2>/dev/null | grep -E -o "java-[0-9.]*-openjdk")
    if [ $(echo $?) == "0" ]; then
      echo "Version $java_installed is installed, do you want to remove this version ?"
      while [[ $REP_JAVA != "y" && $REP_JAVA != "n" ]]; do
        read -rp "Remove $java_installed [y/n]: " -e REP_JAVA
      done
      if [ $REP_JAVA == "y" ]; then
        printf "\nRemove $java_installed\n"
        yum remove -y $java_installed
        printf "\nInstall java-"$@"-openjdk\n"
        yum install -y java-"$@"-openjdk
      else
	printf "Keep $java_installed\n"
      fi
    else
      printf "\nInstall java-"$@"-openjdk\n"
      yum install -y java-"$@"-openjdk
    fi
}


package_java="1.8.0"
packgae_e="elasticsearch"
package_k="kibana"
package_l="logstash"
mem=1G
ipE=localhost #unused
ipk=localhost #unused
portE=9200    #unused
portK=5601    #unused
portL=5044    #unused

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

  esac
  shift
done 

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
    sed -i "s/^-Xms.*$/-Xms$mem/" /etc/elasticsearch/jvm.options
    sed -i "s/^-Xmx.*$/-Xmx$mem/" /etc/elasticsearch/jvm.options
    
    systemctl daemon-reload
    systemctl enable --now elasticsearch.service

    #test if works
    if curl -XGET "localhost:9200" &>/dev/null;then echo "$package_e work"; else echo "$package_e doesn't work"; exit 1; fi
fi


#Kibana //TODO 

if isinstalled $package_k; then 
    echo "$package_k déjà installé" 
else 
    yum -y install $package_k
    sed -i 's/#server.port:/server.port:/' /etc/kibana/kibana.yml #port du serveur k
    sed -i 's/#server.host:/server.host:/' /etc/kibana/kibana.yml #ip   du serveur k //TODO host donne l'accès: localhost=que le pc, 192.x.x.x donne accès à tous les machine qui on accès a cette ip
    sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/' /etc/kibana/kibana.yml #add du serveur e pour les lié
    
    systemctl enable --now kibana
    
    firewall-cmd --add-port=5601/tcp --permanent # autorisé les connection externe
    firewall-cmd --reload
    
    if curl -XGET "localhost:5601" &>/dev/null;then echo "k work"; else echo "k doesn't work"; exit 1 ; fi # //TODO remplacer localhost par l'ip voulu 
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
    chown --recursive logstash /var/log/logstash
    chown --recursive logstash /var/liv/logstash
    chmod -R 755 /usr/share/logstash
    chmod -R 755 /var/lib/logstash
fi
