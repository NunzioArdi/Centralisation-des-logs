#/bin/bash
##TODO config intéractive, ip et mem, verifier version 

usage="\
Installe elk pour centos 8
"

function isinstalled {
  if yum list installed "$@" 1>/dev/null 2>&1; then
    true
  else
    false
  fi
}

package_java="java-1.8.0-openjdk"
packgae_e="elasticsearch"
$package_k="kibana"
$package_l="logstash"
$mem=1G
$ipE=localhost #unused
$ipk=localhost #unused
$portE=9200    #unused
$portK=5601    #unused
$portL=5044    #unused

#1. JAVA

if isinstalled $package_java; then 
    echo "$package_java déjà installé"; 
else 
     yum -y install $package_java
fi


#2 Elasticsearch 7

rpm ––import https://artifacts.elastic.co/GPG-KEY-elasticsearch



dnf update

if isinstalled $package_e; then 
    echo "$package_e déjà installé" 

else 

    cat <<EOF | tee /etc/yum.repos.d/elasticsearch.repo
[elasticstack]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

    yum -y install $package_e
    
    sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml #restraindre l'accès (accès par k)
    sed -i 's/#http.port: 9200/http.port: 9200' /etc/elasticsearch/elasticsearch.yml

    #ram
    sed -i "s/^-Xms.*$/-Xms$mem/" /etc/elasticsearch/jvm.options 
    sed -i "s/^-Xmx.*$/-Xmx$mem/" /etc/elasticsearch/jvm.options

    systemctl daemon-reload
    systemctl enable --now elasticsearch.service

    #test si fonctionne
    if curl -XGET "localhost:9200" &>/dev/null;then echo "e work"; else echo "e doesn't work"; exit(1); fi
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
    
    if curl -XGET "localhost:5601" &>/dev/null;then echo "k work"; else echo "k doesn't work"; exit(1); fi # //TODO remplacer localhost par l'ip voulu 
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
