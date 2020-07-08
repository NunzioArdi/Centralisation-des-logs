# Configuration pour récupérer les log des switch Cisco ASA
Il sera donné les commandes pour que les switchs envoient leurs logs et une configuration logstash pour les indexer. Un seul problème existe, on ne peut pas envoyer les logs sur plusieurs serveurs: on ne peut pas les sauvegarder dans le serveur ELK et dans le serveur Rsys. La sauvegarde dans ELK est privilégié pour la partie d'analyse que l'on peut faire.

[Issue #3](https://github.com/NunzioArdi/cenlogsstage/issues/3)

## Commandes cisco
```
# conf t
# logging enable
# logging trap <severity_level>
# logging facility <number>
# logging host interface_name ip_address [tcp[/port] | udp[/port]]
# logging timestamp [rfc5424]
# exit
# write
```
- trap: indique la severity maximale des logs. informational est très verbeux mais indique tout ce que les utilisateurs fondent.
- facility: si l'on sépare les logs cisco du reste, cela n'a d'importance et l'on peut mettre 0.  
- host: l'ip où l'on envoie les logs
- timestamp: ajoute le temps. On peut indiquer d'écrire le temps dans au format RFC5424 mais cela n'a pas grand intérêt puisque la précision maximale du temps de base est la seconde.

Un log aura ce format à la sortie (exemple):
`<190>2020-07-03T15:27:28+02:00: %ASA-6-302016: Teardown UDP connection 2517** for DR6:1**.***.***.***/***** to identity:2**.***.***.***/***** duration 0:00:00 bytes 0`
## Logstash
Les filtres qui seront appliqués proviennent de [cette page](https://jackhanington.com/blog/2015/06/16/send-cisco-asa-syslogs-to-elasticsearch-using-logstash/) et du dépôt git de logstash ils ont été mise à jour et adapté pour fonctionner sur la dernière version d'ELK (7.8) et en fonction de nos besoins.
La configuration d'exemple se trouve dans le fichier [cisco-asa.conf](cisco-asa.conf)
Cette configuration permet d'extraire le maximum d'informations à l'aide de filtres fournies par logstash. Il permet aussi d'utiliser geoIP pour utiliser la map de Kibana pour visualiser la provenance des requêtes. Elle utilise aussi pour l'index le système de cycle de vie qui sera à configurer dans l'*Index Template*.
Le fichier [sysco-asa](sysco-asa) est quand à lui à ajouter dans le même dossier que les fichiers de conf. Il ajoute des patterns utilisés dans la configuration qui ne sont pas présentes.

## Elasticsearch
Pour pouvoir utiliser correctement toutes ces données, il faut appliquer un mapping sur l'index. Ce code JSON sera à importer dans la création d'index sur Kibana où a ajouté dans la requête REST Elasticsearch.
```json
{"_doc":{
  "_meta":{},
  "_source":{},
  "properties":{
    "err_icmp_type":{"type":"long"},
    "reason":{"type":"text"},
    "src_interface":{"type":"text"},
    "orig_src_ip":{"type":"ip"},
    "orig_src_port":{"type":"long"},
    "seq_num":{"type":"long"},
    "syslog_severity":{"type":"keyword"},
    "protocol":{"type":"keyword"},
    "cisco_message":{"type":"text"},
    "orig_dst_port":{"coerce":true,"index":true,"ignore_malformed":false,"store":false,"type":"long","doc_values":true},
    "action":{"type":"keyword"},
    "icmp_code":{"type":"long"},
    "icmp_code_xlated":{"type":"long"},
    "src_fwuser":{"type":"text"},
    "icmp_seq_num":{"type":"long"},
    "group":{"type":"text"},
    "dst_mapped_port":{"type":"long"},
    "orig_dst_fwuser":{"type":"text"},
    "err_dst_ip":{"type":"ip"},
    "err_src_ip":{"type":"ip"},
    "err_dst_interface":{"type":"text"},
    "spi":{"type":"text"},
    "src_mapped_ip":{"type":"ip"},
    "drop_rate_id":{"type":"text"},
    "orig_dst_ip":{"type":"ip"},
    "src_xlated_ip":{"type":"ip"},
    "drop_rate_current_burst":{"type":"long"},
    "dst_ip":{"type":"text"},
    "err_icmp_code":{"type":"long"},
    "drop_total_count":{"type":"long"},
    "src_mapped_port":{"type":"long"},
    "drop_rate_max_burst":{"type":"long"},
    "dst_mapped_ip":{"type":"ip"},
    "duration":{"type":"text"},
    "err_src_fwuser":{"type":"text"},
    "src_ip":{"type":"ip"},
    "tunnel_type":{"type":"text"},
    "direction":{"type":"keyword"},
    "err_src_interface":{"type":"text"},
    "orig_src_fwuser":{"type":"text"},
    "drop_rate_max_avg":{"type":"long"},
    "drop_rate_current_avg":{"type":"long"},
    "geoip":{"type":"object","properties":{
      "timezone":{"type":"text"},
      "ip":{"type":"ip"},
      "latitude":{"type":"half_float"},
      "continent_code":{"type":"keyword"},
      "city_name":{"eager_global_ordinals":false,"index_phrases":false,"fielddata":false,"norms":true,"index":false,"store":false,"type":"text"},
      "country_code2":{"type":"keyword"},
      "country_name":{"eager_global_ordinals":false,"norms":false,"index":false,"store":false,"type":"keyword","split_queries_on_whitespace":false,"doc_values":true},
      "dma_code":{"type":"text"},
      "country_code3":{"type":"keyword"},
      "location":{"type":"geo_point"},
      "region_name":{"eager_global_ordinals":false,"norms":false,"index":false,"store":false,"type":"keyword","split_queries_on_whitespace":false,"doc_values":true},
      "postal_code":{"eager_global_ordinals":false,"index_phrases":false,"fielddata":false,"norms":true,"index":true,"store":false,"type":"text","index_options":"positions"},
      "longitude":{"type":"half_float"},
      "region_code":{"type":"keyword"}}
    },
    "orig_protocol":{"type":"text"},
    "ciscotag":{"type":"text"},
    "dst_interface":{"type":"text"},
    "drop_type":{"eager_global_ordinals":false,"index_phrases":false,"fielddata":false,"norms":true,"index":true,"store":false,"type":"text","index_options":"positions"},
    "src_port":{"coerce":true,"index":true,"ignore_malformed":false,"store":false,"type":"long","doc_values":true},
    "is_remote_natted":{"type":"text"},
    "connection_id":{"coerce":true,"index":true,"ignore_malformed":false,"store":false,"type":"long","doc_values":true},
    "bytes":{"coerce":true,"index":true,"ignore_malformed":false,"store":false,"type":"long","doc_values":true},
    "dst_port":{"coerce":true,"index":true,"ignore_malformed":false,"store":false,"type":"long","doc_values":true},
    "is_local_natted":{"type":"text"},
    "err_dst_fwuser":{"type":"text"},
    "user":{"type":"text"}
  }
}}
```

## Note
Il est possible que certains champs soient oublié. Certains champs avec des nombres sont mis sur *long* pour ne pas avoir de problème mais cela pourrait être optimisé. Tous les champs proviennent des filtres grok inclus dans logstash.

Certains messages ASA n'ont pas besoin d'avoir un filtre personnalisé; exemple avec ASA-3-444303 ou le message est un code erreur avec un message.

## Ajouter des filtres
Pour rajouter des filtres sur un log qui n'en aurait pas, il faut le ciscotag. Il va nous permettre de voir dans la documentation cisco qu'elles sont les variables. Ensuite, on créé la règles grok qui doit pouvoir lire le message du log qui on l'ajoute dans le fichier [syslog-asa](syslog-asa). Enfin on ajoute notre règle grok dans le filtre grok des messages cisco.