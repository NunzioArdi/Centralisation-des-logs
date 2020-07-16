# Configuration
Ce dossier regroupe à la fois des exemples de configuration et des documents explicants le fonctionnement de certaines fonctionnalités.

Un fichier README est présent dans les dossiers des logiciels pour expliquer leur fonctionnements et présenter des fonctionnalitées.

## Logiciel
- [Logstash](Logstash/)
- [Filebeat](Filebeat/)
- [Kibana](Kibana/)
- [Rsyslog](Rsyslog/)

## Configuration pour certains types de logs pour rsys et ELK
- log de base
    - [conf rsyslog ](Rsyslog/log_de_base.conf)
    - [conf logstash](Logstash/filter.log.conf)
- log DNF (centos 7-8) 
    - [conf filebeat](Filebeat/input.dnf.yml)
    - [conf logstash](Logstash/filter.dnf.conf)
- log anaconda (centos 6 (7-8?))
    - [conf filebeat](Filebeat/input.anaconda.yml)
    - [conf logstash](Logstash/filter.anaconda.conf)
- log syslog en RFC5424
    - [conf rsys]
    - [conf filebeat]
    - [conf logstash](Logstash/filter.rfc5424.conf)
- log cisco-asa
    - [README](Cisco-ASA/)

## Autres tutoriels
- [Supression automatique des logs](Suppression-logs/)