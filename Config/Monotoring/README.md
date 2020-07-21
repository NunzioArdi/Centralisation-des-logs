# Surveillance de l'installation
L'observabilité et le monitoring sont des éléments importants puisqu'ils permettent de voir en direct et de surveiller l'état des services, pour détecter un problème.
Dans kibana, il y 2 section: la section *Observability* qui contient les onglets *Logs*, *Metrics*, *APM*, *Uptime* et la section *Stack Monitoring* qui est dédier au logiciel de la suite ELK.

Nous allons voir dans un premier temps comment activer le monitoring des logiciels Elastic. Puis comment mettre en place l'observability pour les logiciels de la suite ELK et pour d'autre programme.

*Note: Le monitoring est une fonctionnalité x-pack, mais la plupart des fonctions sont disponible dans la licence basique.*
## Le monitoring
Le monitoring permet de connaitre le nombre de logiciels ELK actifs, leur état et d'avoir des statistiques d'utilisation.

### Configuration
#### Elasticsearch
Il faut rajouter ce paramètre dans le fichier de configuration
```yaml
#/etc/elasticsearch/elasticsearch.yml
xpack.monitoring.collection.enabled: true
```

#### Kibana
Activer de base.
Il est possible de modifier des paramètres dans le fichier de configuration en rapport avec le monitoring et l'affichage mais nous en n'avons pas besoin.

#### Logstash
Activer de base

#### Beat
Il existe 2 méthodes pour envoyer les données des agents Beat au serveur ELK. Soit ils envoient eux même leurs données, soit c'est metricbeat qui ce charge de tout récupérer.

##### Internal collection
<img src="monitoring_beat_to_e.png" height="35%">
<img src="monitoring_beat_to_l.png" height="35%"> <br>
L'agents Beat envoye ces données.<br>
Si le agents Beat est configuré pour envoyer des données à la sortie Elasticsearch, une seul ligne n'est qu'a modifier:
```yaml
#/etc/*beat/*beat.yml
monitoring.enabled: true
```

Si le agents Beat n'est pas configuré pour envoyer des données à la sortie Elasticsearch:
```yaml
#/etc/*beat/*beat.yml
monitoring
  enabled: true
  elasticsearch:
    hosts: ["https://example2.com:9200"]
```

##### Metrics Beat
<img src="monitoring_beat_to_metric_to_e.png" height="30%">
<img src="monitoring_beat_to_metric_to_l.png" height="30%"> <br>
Utilise l'agent Metricbeat pour envoyer les données.<br>
*Note: non tester*

1. Config d'un agent Beat

```yaml
#/etc/*beat/*beat.yml
http.enabled: true
http.port: 5067 #(5066 default port monitoring)
monitoring.enabled: false
```

2. Config de l'agent Metricbeat

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




# draft
Les options de monitorings sont inclus dans chaque programmes. Il faut les activers en modifiants les paramètres.
[Les paramètres](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-monitor-legacy.html#)
. ## Stockage
Elle sont stocker dans l'index cacher `	.monitoring-<programme>-<version>-<date>`.

https://www.elastic.co/fr/blog/elastic-stack-monitoring-with-metricbeat-via-logstash-or-kafka
https://www.elastic.co/guide/en/beats/filebeat/current/monitoring-metricbeat-collection.html
