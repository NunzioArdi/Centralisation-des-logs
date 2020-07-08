# Sauvegarde et analyse de log
Ce dépôt regroupe de la documentation et des exemples pour configurer 1 serveur de sauvegarde de logs Rsyslog et un serveur d'analyse de log ELK.
Cette partie explique l'installation des logiciels et d'une rapide configuration pour les rendres fonctionnelles.
Les configurations se trouvent dans le dossier [Config](Config).

Ce travail à été réalisé lors du stage de 2nd année du DUT Informatique.

## Note
Les commandes commençant par `$` sont des commandes utilisateur.
Les commandes commençant par `#` sont des commandes root.

Si la configuration est sur un réseau fermé, penser à désactiver SELinux, les Firewall et de reboot.
```
# sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
```
Un script est disponible pour installer automatiquement les logiciels sur Centos 7 et 8

## Rsyslog
Fichier de configuration serveur et client : `/etc/rsyslog.conf`
Emplacement des fichiers de logs : `/var/log`.
Attention, les versions plus récentes de rsyslog utilisent une nouvelle syntaxe qui est incompatible avec les anciennes versions. Mais l'ancienne syntaxe est rétrocompatible.
[Documentation officiel](https://www.rsyslog.com/doc/master/index.html)

### Installation
Rsyslog est disponible officiellement sur Ubuntu, Debian et RHEL/Centos. Rsyslog est généralement installé ces distributions. Les commandes d'installation de plusieurs distributions sont disponibles sur ce [site](https://software.opensuse.org/download.html?project=home%3Argerhards&package=rsyslog)

### Configuration serveur
Pour que rsys puisse recevoir des données, il faut activer le module de réception par internet. On utilise l'UDP mais le TCP est aussi utilisable. Mettre ce code dans les premières lignes.
Nouvelle syntaxe
```
module(load="imudp")
input(type="imudp" port="514")
```
Ancienne syntaxe
```
$ModLoad imudp
$UDPServerRun 514
```

### Configuration du client
Qu'une seule ligne est nécessaire pour envoyer les logs au serveur. Elle est à mettre à la toutes fin du fichier. Pour envoyer en TCP, mettre deux @. 
```
*.* @<IP>:<PORT> 
```

## ELK
Les logiciels d'Elastic peuvent être installé en téléchargent les binaires ou un ajoutant leur dépot. Tout est donné sur les pages de télécharement des logiciels.
La version des logiciels Elastic utilisé dans cette documentation dès la `7.8.0`. La version que l'on télécharge est la version `basic` et non `OSS`. Néanmoins, Elastic a libéré toutes les sources de ces logiciels, même celles réservés aux fonctionnalitées payantes.
[Elasticsearch](https://www.elastic.co/fr/downloads/elasticsearch)
[Kibana](https://www.elastic.co/fr/downloads/kibana)
[Logstash](https://www.elastic.co/fr/downloads/logstash)
[FileBeat](https://www.elastic.co/fr/downloads/beats/filebeat)
[WinLogBeat](https://www.elastic.co/fr/downloads/beats/winlogbeat)

### Configuration Elasticsearch
`/etc/elasticsearch/elasticsearch.yml`
```yml
network.host: localhost
http.port: 9200
```

### Configuration Kibana
`/etc/kibana/kibana.yml`
- <IP_E> peut très bien être localhost
```yml
server.port: 5601
server.host: <IP> #donne accès
elasticsearch.host: ["<IP_ELASTICSEARCH>:<PORT_ELASTICSEARCH>"]
```

### Configuration Logstash
`/etc/logstash/config.d/confTutorial.conf`
```
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
```
### Configuration Filebeat
Enverra le nouveau contenu des fichiers *.log et du fichier messages.
`/etc/filebeat/filebeat.yml`
```yml
filebeat.inputs:
- type: log
  paths:
    - /var/log/*.log
    - /var/log/*/*.log
- type: log
  paths: 
    - /var/log/messages
  tags: [messages]
```
Commenter la partie `output.elasticsearch`
```yml
output.logstash:
  hosts: ["<IP_LOGSTASH>:5044"]
```
### Configuration WinLogBeat
`<EMPLAEMENT_DU_DOSSIER>\winlogbeat.yml`
Commenter la partie `output.elasticsearch`
```yml
output.logstash:
  hosts: ["<IP_LOGSTASH>:5044"]
```
Executer le fichier `install-service-winlogbeat.ps1` pour le lancer et l'installer en tant que service.
Ou executer le programme `winlogbeat.exe`.