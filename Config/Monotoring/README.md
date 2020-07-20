# Etat de l'installation
*Note: cette partie est encore brouillon*
Il y a les donnée de monitoring: cela sert à voir l'état des programmes de la suite Elastic.<br>
Il y a les données metric: permet de faire une analyse d usysteme t des programme Elastic 

## Activer le monitoring
Les options de monitorings sont inclus dans chaque programmes. Il faut les activers en modifiants les paramètres.
[Les paramètres](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-monitor-legacy.html#)
## Kibana
Activer de base.

## Elasticsearch
Activer de base.

## Logstash
Activer de base

## Beat
N'est pas activé de base.
Il existe 2 méthodes pour envoyer les donnée des clients beat au serveur ELK. Soit les client beat envoie eux même les données, soit c'est metricbeat qui ce charge de tout récupérer.
https://www.elastic.co/fr/blog/elastic-stack-monitoring-with-metricbeat-via-logstash-or-kafka
### Internal collection
Utilise le client beat pour envoyer les données.<br>
Si le client beat est configuré pour envoyer des données à la sortie Elasticsearch, une seul ligne n'est qu'a modifier
```yaml
#/etc/filebeat/filebeat.yml
monitoring.enabled: true
```

Si le client beat n'est pas configuré pour envoyer des données à la sortie Elasticsearch:
```yaml
#/etc/filebeat/filebeat.yml
monitoring
  enabled: true
  elasticsearch:
    hosts: ["https://example2.com:9200"]
```

### Metrics Beat
Utilise le client Metricbeat pour envoyer les données.<br>
*non tester* https://www.elastic.co/guide/en/beats/filebeat/current/monitoring-metricbeat-collection.html
*pas de recommendation sur ce qui est le mieux*


## Stockage
Elle sont stocker dans l'index cacher `	.monitoring-<programme>-<version>-<date>`.