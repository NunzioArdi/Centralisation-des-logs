# Monitoring
Le monitoring permet de connaitre le nombre de logiciels ELK actifs, leur état et d'avoir des statistiques d'utilisation.
Dans kibana, on trouve cette section dans *Stack Monitoring*.

*Note: Le monitoring est une fonctionnalité x-pack, mais la plupart des fonctions sont disponible dans la licence basique.*

## Configuration
### Elasticsearch
Pour activer cette fonctionnalité, il faut rajouter ce paramètre dans le fichier de configuration:
```yaml
#/etc/elasticsearch/elasticsearch.yml
xpack.monitoring.collection.enabled: true
```

### Kibana
Le monitoring est activer par défaut. Il est possible de modifier des paramètres dans le fichier de configuration `/etc/kibana/kibana.yml` en rapport avec le monitoring et l'affichage, mais nous en n'avons pas besoin.

### Logstash
Il existe 2 méthodes pour envoyer les données de monitoring. Soit en passant par logstash (legacy), soit en passant par l'agent Metricbeat. <br>
La configuration du monitoring dans le fichier de configuration :
```yaml
#/etc/logstash/logstash.yml
xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch:
  hosts: ["192.168.0.2:9200"]
```

### Beat
Il existe 2 méthodes pour envoyer les données de monitoring. Soit en passant par lui même (legacy), soit en passant par l'agent Metricbeat.

#### Legacy
<img src="monitoring_beat_to_e.png" width="462"> ou  <img src="monitoring_beat_to_l.png" width="462"> <br>
L'agents Beat envoye ces données.<br>
Si le agents Beat est configuré pour envoyer des données à la sortie Elasticsearch, une seul ligne n'est qu'a modifier:
```yaml
#/etc/*beat/*beat.yml
monitoring.enabled: true
```

Si le agents Beat n'est pas configuré pour envoyer des données à la sortie Elasticsearch:
```yaml
#/etc/*beat/*beat.yml
monitoring.enabled: true
monitoring.elasticsearch:
  hosts: ["http://example.com:9200"]
```

#### Metricbeat
<img src="monitoring_beat_to_metric_to_e.png" width="462"> ou  <img src="monitoring_beat_to_metric_to_l.png" width="462"> <br>
Utilise l'agent Metricbeat pour envoyer les données.<br> 
*Note: non tester*

1. Configuration d'un agent Beat

```yaml
#/etc/*beat/*beat.yml
http.enabled: true
http.port: 5067 #(5066 default port monitoring)
monitoring.enabled: false
```

2. Configuration de l'agent Metricbeat

On active le module beat
```
# metricbeat modules enable beat-xpack
```
On le configure
```yaml
#/etc/metricbeat/modules.d/beat-xpack.yml
- module: beat
  metricsets:
    - stats
    - state
  period: 10s
  hosts: ["http://<adress>:5067"] #list
  xpack.enabled: true
```
Puis on configure la sortie (Logstash ou Elasticsearch)

## Problème
Il est possible qu'un agent beat n'apparaisse pas dans le cluster principale mais dans un autre cluster appelé "*Standalone Cluster*". Pour corriger ce problème ou pour le prévenir, il faut ajouter à la configuration de l'agent beat l'UUID du cluster Elasticsearch que l'on utilise pour le monitoring.
```json
GET _cluster/state/version
{
  "cluster_name" : "<cluster_name>",
  "cluster_uuid" : "<cluster_uuid>",
  "version" : 0,
  "state_uuid" : "<state_uuid>"
}
```
Ensuite, on ajoute l'uuid au fichier de configuration de l'agent beat.
```yaml
monitoring:
  cluster_uuid: "<cluster_uuid>"
```

## Note
Les données de surveillance sont stockées dans un index caché `.monitoring-<PROGRAMME>-<VERSION>-<DATE>`.<br>
La gestion du cycle de vie des données de monitoring est une fonctionnalité x-pack payante.<br>
*À vérifier:* il semble que ces données s'accumulent et ne soient pas automatiquement supprimées au bout de x temps.

## Source
- https://www.elastic.co/fr/blog/elastic-stack-monitoring-with-metricbeat-via-logstash-or-kafka
- https://discuss.elastic.co/t/filebeat-creates-a-standalone-cluster-in-kibana-monitoring/188663/5