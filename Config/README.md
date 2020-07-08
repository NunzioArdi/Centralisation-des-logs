# Configuration
Ce dossier regroupe à la fois des exemples de configuration et des documents explicants le fonctionnement de certaines fonctionnalités.

## Configuration de transmition des log pour rsys et ELK
- log de base
    - [conf logstash][Logstash/filter.log.conf]
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
    - [README](Cisco-ASA/README.md)