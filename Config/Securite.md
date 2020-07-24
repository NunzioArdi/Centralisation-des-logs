# Sécurité

*Note: La sécurité est une option x-pack mais la plupart des options sont inclues dans la licence basique*

## Connection par mot de passe
Pour pouvoir accéder à l'interface kibana et que pour les programmes ELK utilisent une connexion.

### Elasticsearch
- Modifier `/etc/elasticsearch/elasticsearch.yml`
```yaml
xpack.security.enabled: true
xpack.security.audit.enabled: true
discovery.type: signle-node
# commenter les lignes suivante
#discovery.seed_hosted
#cluser.initial_master_nodes
``` 
- Lancer elasticsearch
- Exécuter cette commande `bin/elasticsearch-setup-passwords interactive`. Cela permet de configurer des mots de passe pour les comptes utilisateur interne.

### Kibana
    - Modifier `/etc/kibana/kibana.yml`
```yaml
elasticsearch:
  username: "kibana_system"
  password: "*"
```
- 
  - Lancer Kibana
  - Allez sur l'interface web de kibana et utiliser les identifiants `Elastic` `<mot_de_passe>`

Après cette configuration, des options *Security* vont apparaitre dans *Stack Management*.
Il est maintenant possible de créer des utilisateurs et des roles avec plus ou moins de permission pour le controle d'elasticsearch ou de kibana.

### Logstash
Pour pouvoir envoyer des données, il va falloir créer un rôle et un utilisateur. On utilisera la *Console* dans *Dev Tools* de Kibana
```json
POST _security/role/logstash_writer
{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"], 
  "indices": [
    {
      "names": [ "*" ], 
      "privileges": ["write","create","delete","create_index","manage","manage_ilm"]  
    }
  ]
}
```
`names` est un tableau contenant le nom des indices dans lequels ce rôle aurra le droit d'utilisé ces privilège.
Pour créer un rôle qui puisse voir les indices, il faut lui mettre les permitions `"read","view_index_metadata"`.

```json
POST _security/user/logstash_internal
{
  "password" : "<mot-de-passe>",
  "roles" : [ "logstash_writer"],
  "full_name" : "Utilisateur interne de Logstash"
}
```
`logstash_internal` sera le nom de cette utilisateur.

Ensuite dans les paramètre du plugin elasticsearch on rajoute
```conf
user => "logstash_internal"
password => "<mot-de-passe>"
```

### Agent Beat
On crée un rôle pour setup les index templates, les dashboards, etc.
La partie indice peut être modifier en fonction des indices que l'on a besoin. 
```json
PUT _security/role/beats_setup
{
  "cluster": [ "monitor", "manage_ilm", "manage_ml", "indices:admin/template/put" ],
  "indices": [
    {
      "names": [ "filebeat-*" ],
      "privileges": [ "manage", "read" ]
    },
    {
      "names": [ "winlogbeat-*" ],
      "privileges": [ "manage", "read" ]
    },
    {
      "names": [ "metricbeat-*" ],
      "privileges": [ "manage" ]
    },
    {
      "names": [ "heartbeat-*" ],
      "privileges": [ "manage" ]
    }
  ],
  "metadata" : { "version" : 1 },
  "transient_metadata": { "enabled": true }
}
```

On crée un rôle pour que les données puissent être envoyer au indices (Si l'envoie se fait par Elasticsearch)
```json
PUT /_security/role/beats_writer
{
  "cluster": [ "monitor", "cluster:admin/ingest/pipeline/get", "read_ilm", "manage_index_templates"],
  "indices": [
    {
      "names": [ "filebeat-*" ],
      "privileges": [ "create_doc", "view_index_metadata" ]
    },
    {
      "names": [ "winlogbeat-*" ],
      "privileges": [ "create_doc", "view_index_metadata" ]
    },
    {
      "names": [ "metricbeat-*" ],
      "privileges": [ "create_doc", "view_index_metadata" ]
    },
    {
      "names": [ "heartbeat-*" ],
      "privileges": [ "create_doc", "view_index_metadata" ]
    }
  ],
  "metadata" : { "version" : 1 },
  "transient_metadata": { "enabled": true }
}
```

Enfin on crée un utilisateur pour le client beat
```json
POST _security/user/beats_internal
{
  "password" : "<mot-de-passe>",
  "roles" : [ "kibana_admin", "ingest_admin", "beats_admin", "beats_setup", "beats_writer"],
  "full_name" : "Utilisateur pour client Beat"
}
```


## Source
- https://www.elastic.co/guide/en/elasticsearch/reference/7.8/configuring-security.html
- https://www.elastic.co/guide/en/kibana/current/kibana-authentication.html
- https://www.elastic.co/guide/en/logstash/current/ls-security.html
- https://github.com/elastic/beats/issues/10241#issuecomment-511943737