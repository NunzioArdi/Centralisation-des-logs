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
*Brouillon, ne marche pas*
#### Setup


```json
POST _security/user/beat_setup
{
  "password" : "<mot-de-passe>",
  "roles" : [ "kibana_admin", "ingest_admin", "beats_admin"],
  "full_name" : "Utilisateur de setup des Beat"
}
```
```json
POST _security/role/winlogbeat_writer
{
  "cluster": ["monitor", "read_ilm"], 
  "indices": [
    {
      "names": [ "winlogbeat-*" ], 
      "privileges": ["create_doc","view_index_metadata","create_index"]  
    }
  ]
}
```
```json
POST _security/user/winlogbeat_internal
{
  "password" : "<mot-de-passe>",
  "roles" : [ "winlogbeat_writer"],
  "full_name" : "Internal Winlogbeat User"
}
```
<style>
.red {
  color: red;
}
</style>

*Erreur, winlogbeat*
```json
{
  "error": {
    "root_cause": [
      {
        "type": "security_exception",
        "reason": "action [indices:admin/template/put] is unauthorized for user [winlogbeat_internal]"
      }
    ],
    "type": "security_exception",
    "reason": "action [indices:admin/template/put] is unauthorized for user [winlogbeat_internal]"
  },
  "status": 403
}
```




# Source
- https://www.elastic.co/guide/en/elasticsearch/reference/7.8/configuring-security.html
- https://www.elastic.co/guide/en/kibana/current/kibana-authentication.html
- https://www.elastic.co/guide/en/logstash/current/ls-security.html