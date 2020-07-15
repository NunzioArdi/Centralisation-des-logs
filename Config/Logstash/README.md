# Logstash
> Logstash est un moteur de collecte et de traitement des données via plug-in. Il est doté de nombreux plug-ins qui permettent de configurer facilement l'outil pour collecter, traiter et transférer les données dans un grand nombre d'architectures variées.

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
    "host": "56.67.78.89",
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
Les plugins que l'on utilisera le plus seront `beats` (pour les cients beats) et `udp`/`tcp`. Pour les 2, il faut indiquer un port d'entrer pour que les clients puissent envoyer leur données. Il peut très bien avoir plusieurs fois un même plugins mais avec d'autres ports.

Une option pratique est l'ajout de tags; utile dans les filtres pour faire des conditions.

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
1 paramètre obligatoire: `hosts`. `index` va donner un nom à l'index dans elasticsearch. `ilm_*` sont des paramètres que l'on voit dans [Supression de log](../Suppression-logs/ILM.md). `manage_template => false` indique que l'on veut un modèle d'index entièrement personnalisé.

## Filter
Configure les [plugins](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html) pour rendre l'analyse du log dans elasticsearch possible. Il y a de nombreux plugins mais certains seront très utiles.

### Filtre [Grok](https://www.elastic.co/guide/en/logstash/7.8/plugins-filters-grok.html)
Analyse un texte arbitraire et le structure.
C'est comme ça qu'avec un simple log, on peut le décortiquer pour en extraire des information et les mettre dans des champs analysable par elasticsearch. Voici l'exemple donné dans [`filter.anaconda.conf`](filter.anaconda.conf)
```
grok {
   match => [
      "message", "%{TIME} +%{LOGLEVEL:severity_text} +: +(?<message>(.)*)"
   ]
   overwrite => [ "message" ]
   add_tag => ["grokmatch", "nosyslog"]
}
```
Le paramètre obligatoire est `match` qui va vérifier si le log que l'on récupère correspond au paterne indiqué. `message` indique que la source que l'on veut analyser est le champs message.


Grok est un langage qui utilise des règles regex et des paternes pour en sortir des informations. Par exemple dans l'exemple précédent:
```
%{TIME} +%{LOGLEVEL:severity_text} +: +(?<message>(.)*)
|         |                             |            
|         |                             |-> utilise le paterne personalisé (.)* et met le contenue dans le champ message
|         |
|         |->Utiliser le paterne LOGLEVEL et mettre le contenue dans le champ severity_text
|
|-> Utilise le pattern prédéfinit TIME
|
|-->TIME (?!<[0-9])%{HOUR}:%{MINUTE}(?::%{SECOND})(?![0-9]) => il utilise les paternes HOUR, MINUTE, SECOND
|
|--->HOUR (?:2[0123]|[01]?[0-9])
|--->MINUTE (?:[0-5][0-9])
|--->SECOND (?:(?:[0-5][0-9]|60)(?:[:.,][0-9]+)?)
```
On remarque de `TIME` na pas de sortie, car ici on ne veut pas s'en servir.<br>
On remarque également que `message` (le message du log) porte le même nom que le champ qui contenait le log original. Pour pouvoir le remplacer, le paramètre `overwrite` est nécessaire.<br>
Enfin on ajoute 2 tags avec `add_tag` qui est un paramètre générique. Le tag `grokmatch` peut nous servir à faire des conditions. Si le filtre grok échoue, le tag `_grokparsefailure` sera rajouté, modifiable avec le paramètre `tag_on_failure`.

La liste des paternes est disponible dans le [code source](https://github.com/logstash-plugins/logstash-patterns-core/tree/master/patterns). Pour essayer une règle grok ou les consulter plus facilement, le site http://grokdebug.herokuapp.com/ est très pratique (ATTENTION, le site envoie des requêtes POST). L'outil *grok debugger* est aussi disponible dans kibana. Il est tout à fait possible de rajouter ses propres paternes, en les définissants dans le fichier conf ou en créant un fichier les regroupant tout en indiquant dans la conf d'utiliser ce fichier.

### Filtre [ruby](https://www.elastic.co/guide/en/logstash/7.8/plugins-filters-ruby.html)
Exécute du code ruby. On peut récupérer la valeur des champs et en créer grâce à l'[API Event](https://www.elastic.co/guide/en/logstash/7.8/event-api.html "Doc sur l'api event") fournis.
Continuons avec l'exemple précédent. On a créé et mis une valeur dans le champ `severity_text`. Mais anaconda utilise d'autres termes non standard et l'on veut que la severity soit un chiffre. Des commentaires sont mis dans le fichier d'exemple pour comprendre tout ce qui est faits.

### Filtre [date](https://www.elastic.co/guide/en/logstash/7.8/plugins-filters-date.html)
Change le timestamp en fonction de la date d'un champ. Utile pour que les évènements dans l'index aient le temps original et pas le temps de la réception par Elasticsearch.
Exemple du [filter.log.conf](filter.log.conf)
```
date {
   match => [ "timestamp", "MMM dd HH:mm:ss", "MMM  d HH:mm:ss"]
   remove_field => ["timestamp"]
}
```
Le paramètre match à 2 valeurs obligatoires: le champ source et le paterne. Il peut avoir plusieurs paternes comme ici.
Ensuite on utilise le paramètre générique `remove_field` pour retirer le champ qui contenait le temps du log.

## Performence
https://www.elastic.co/guide/en/logstash/current/performance-troubleshooting.html

### RAM
Il faut avoir assez de ram pour faire fonctionner Logstash. Sinon des ralentissements apparaiterons.<br>
https://www.elastic.co/guide/en/logstash/current/jvm-settings.html<br>
https://www.elastic.co/guide/en/logstash/current/tuning-logstash.html#profiling-the-heap

### Regex
Les règles regex peuvent prendre pas mal de performence. Un article explique comment obtimiser les règles grok pour éviter de réduire gravement les performences de recherche regex: https://www.elastic.co/fr/blog/do-you-grok-grok

### Pipeline non ordonné
De base, la lecture de les filtres ce fais dans l'ordre. Mais il est possible de ne pas respecter l'ordre et d'augmenter les performences.
Ajouter le paramètre `pipeline.ordered: true` dans le fichier de configuration `logstash.yml`.
*Note*: La configuration fournis à besoin de préserver l'ordre. Ne pas changer ce paramètre.


# Liens
- https://www.elastic.co/fr/blog/a-practical-introduction-to-logstash
