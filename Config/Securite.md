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
Pour pouvoir envoyer des donées, il va falloir créer un rôle et un utilisateur. On utilise ...TODO
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