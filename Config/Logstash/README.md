# Logstash
Logstash est un logiciel qui sert de pipeline entre les logs et elasticsearch. Il va poouvoirt mettre en forme les entréer pour qu'elasticsearch puisse en tirer le meilleur.

Voici un log qui arrive en entrée
```
<190>2020-07-07T15:55:57+02:00: %ASA-5-722032: Group <GroupPolicy_GIGN> User <théodule.béarnaise> IP <66.77.88.99> New TCP SVC connection, no existing connection.
```
Et voila ce qui en sort (partiel) après configuration
```json
{
  "_index": "manual-input-cisco",
  "_type": "_doc",
  "_source": {
    "@timestamp": "2020-07-07T13:55:57.000Z",
    "user": "théodule.béarnaise",
    "group": "GroupPolicy_GIGN",
    "src_ip": "66.77.88.99",
    "tags": [ "cisco-asa", "manual-input", "message_groker", "Whois" ],
    "host": "193.55.237.120",
    "cisco_message": "Group <GroupPolicy_GIGN> User <théodule.béarnaise> IP <66.77.88.99> New TCP SVC connection, no existing connection.\n",
    "syslog_severity": 6,
    "ciscotag": "ASA-5-722032",
    "geoip": {
      "country_code2": "US",
      "timezone": "America/Chicago",
      "country_name": "United States",
      "location": {
        "lon": -97.822,
        "lat": 37.751
      },
      "longitude": -97.822,
      "latitude": 37.751,
      "ip": "66.77.88.99",
      "country_code3": "US"
    }
  }
}
```

Il y a 3 partie dans la configuration de logstash: input, filter, output. Chaqu'un d'entre peut utilise des plugins inclus pour effectué des opérations.

## Configuration Java
Logstash tourne sur Java il certains paramètres doivent être comfigurer pour le faire tourné dans des conditions obtimale. [Doc](https://www.elastic.co/guide/en/logstash/current/jvm-settings.html)

## Input
Configure les [plugins](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-beats.html) pour que des données puissent entrer.
Les plugins que l'on utilisera le plus seront `beats` (pour les lcients beats) et `udp`/`tcp`. Pour les 2, il faut indiquer un port d'entrer pour que les clients puissent envoyer leur données. Il peut très bien avoir plusieur fois un même plugins mais avec d'autres ports.

Une option pratique est l'ajout de tags; partique dans les filtres pour faire des conditions.

```
input {
   beats {
      port => 5044
   }
   udp {
      port => 7842
      tags => ["cisco-asa"]
   }
   udp {
      port => 6666
      tags => ["cisco-asa", "manual-input"]
   }
}
# on pourra différencier les logs pour les 2 entrées udp et faire en sorte que les 2 utilises le même filtre
```

## Output
Configure les [plugins](https://www.elastic.co/guide/en/logstash/current/output-plugins.html) pour que les données sortent.
On utilisera que le plugin `elasticsearch` mais il existe aussi par exemple le plugin `file` pour faire les sorties dans un fichier.

```
output {
   if "cisco-asa" in [tags] and "manual-input" not in [tags] {
      elasticsearch {
         manage_template => false
         hosts => ["localhost:9200"]
         ilm_pattern => "000001"
         ilm_rollover_alias => "cisco-asa"
      }
   }
   else if "manual-input" in [tags] {
      elasticsearch {
         manage_template => false
         hosts => ["localhost:9200"]
         index => "manual-input"
      }
   }
   else {
      elasticsearch {
         manage_template => false
         hosts => ["localhost:9200"]
         ilm_rollover_alias => "test15"
      }
   }
}
```
1 parametre obligatoire: `hosts`. `index` va donnée un nom à l'index dans elasticsearch. `ilm_*` sont des paramètres que l'on vois dans [Supression de log](../Suppression-logs/ILM.md). `manage_template => false` indique que l'on veux un modèle d'index entièrement personalisé.

## Filter
Configure les [plugins](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html) pour rendre l'analyse du log dans elasticsearch possible. Il y a de nombreux plugins mais certains seront très utils.