# Etat de l'installation
Le l'observabilité (et le monitoring) est un éléments important puisse qu'il permet de voir en direct et de surveiller l'état des services, pour détecter un problème.
Dans kibana, il y 2 section: la section *Observability* qui contient les onglets *logs*, *Metrics*, *APM*, *Uptime* et la section *stack monitoring* qui est dédier au logiciel de la suite ELK.

Nous allons voir dans un premier temps comment activé le monitoring des logiciels Elastic. Puis comment mettre en place l'observability pour les logiciels de la suite ELK et pour d'autre programme.

*Note: Le monitoring est une fonctionnalité x-pack, mais la plupart des fonctions sont disponible dans la licence basique.*
## Le monitoring
Le monitoring permet de connaitre le nombre de logiciels ELK actifs, leur état et d'avoir des statistic d'utilisations.

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
N'est pas activé de base.
Il existe 2 méthodes pour envoyer les donnée des clients beat au serveur ELK. Soit les agents Beat envoie eux même les données, soit c'est metricbeat qui ce charge de tout récupérer.
https://www.elastic.co/fr/blog/elastic-stack-monitoring-with-metricbeat-via-logstash-or-kafka
##### Internal collection
Utilise le agents Beat pour envoyer les données.<br>
Si le agents Beat est configuré pour envoyer des données à la sortie Elasticsearch, une seul ligne n'est qu'a modifier
```yaml
#/etc/filebeat/filebeat.yml
monitoring.enabled: true
```

Si le agents Beat n'est pas configuré pour envoyer des données à la sortie Elasticsearch:
```yaml
#/etc/filebeat/filebeat.yml
monitoring
  enabled: true
  elasticsearch:
    hosts: ["https://example2.com:9200"]
```

##### Metrics Beat
Utilise le client Metricbeat pour envoyer les données.<br>
*non tester* https://www.elastic.co/guide/en/beats/filebeat/current/monitoring-metricbeat-collection.html
*pas de recommendation sur ce qui est le mieux*





# draft
Les options de monitorings sont inclus dans chaque programmes. Il faut les activers en modifiants les paramètres.
[Les paramètres](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-monitor-legacy.html#)
## Stockage
Elle sont stocker dans l'index cacher `	.monitoring-<programme>-<version>-<date>`.