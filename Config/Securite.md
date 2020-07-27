# Sécurité

*Note: La sécurité est une option x-pack mais la plupart des paramètres sont inclues dans la licence basique*.<br>
Il existe plusieurs options de sécurité dans la suite ELK. Les activés permet aussi de débloqué quelques options.
Il est possible de sécurisé la connection par mot de passe, par token, de rajouter des certificats ssl, etc.

## Connection par mot de passe
Pour pouvoir accéder à l'interface Kibana sans que tout les utilisteurs puissent avoir accès au options administrateur.
Limite égalment les logiciels Elastics à ce qu'il doivent faire (par exemple en leur limitant l'accès qu'a certains indices).

### Elasticsearch
- Modifier `/etc/elasticsearch/elasticsearch.yml`
```yaml
xpack.security.enabled: true
xpack.security.audit.enabled: true
discovery.type: signle-node
```
```yaml
# commenter les lignes suivante
discovery.seed_hosted:
cluser.initial_master_nodes:
``` 
- Lancer elasticsearch
- Exécuter cette commande `bin/elasticsearch-setup-passwords interactive`. Cela permet de configurer des mots de passe pour les comptes interne.

### Kibana
- Modifier `/etc/kibana/kibana.yml`
```yaml
elasticsearch:
  username: "kibana_system"
  password: "<mot-de-passe>"
```
- Lancer Kibana
- Allez sur l'interface web de kibana et utiliser les identifiants `Elastic` `<mot_de_passe>`

Après cette configuration, des options *Security* vont apparaitre dans *Stack Management*.
Il est maintenant possible de créer des utilisateurs et des roles avec plus ou moins de permission pour le controle d'elasticsearch (indices, monitoring, ...) ou de kibana.

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
output {
  elasticsearch {
    user => "logstash_internal"
    password => "<mot-de-passe>"
  }
}
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

### Monitoring 
Si le monitoring est activé, il faut modifier des paramètres pour autorisé l'envoie de donnée. Elasticsearch intègres des compte dédié a cette tâche. Ces comptes sont: `beats_system`, `logstash_system`, `kibana_system` et `apm_system`.

Il suffit de rajouter ces lignes:
```yaml
monitoring.elasticsearch:
  username: "beats_system"
  password: "<mot_de_passe>"
```

### Keystore
Actuellement, les mots de passe sont écrit en claire dans le fichier de configuration. Pour pouvoir le masquer, on peut utiliser les keystone pour les masquer.

On va prendre pour exemple winlogbeat.
Dans les fichiers de configuration, mettre à la place du mot de passe le nom d'une varible, par exemple `${BEATS_PWD}`.
Ensuite, seulement la première fois, executer la commande `winlogbeat keystore create`.
Puis pour ajouter cette varible et lui attribué une valeur, executer `winlogbeat keystore add BEATS_PWD --force`

#### Problème avec windows
Si vous executer le script pour que les logiciels fonctionnent en service, il ne pourront pas utiliser les ketstones créer.
Pour que cela puisse marcher:
- déplacer le fichiers `winlogbeat.keystore` du dossier data dans `C:\ProgramData\winlogbeat`
- changer la configuration des dossiers du fichier `install-service-winlogbeat.ps1` pour qu'il utilise le dossier courrant

## Source
- https://www.elastic.co/guide/en/elasticsearch/reference/7.8/configuring-security.html
- https://www.elastic.co/guide/en/kibana/current/kibana-authentication.html
- https://www.elastic.co/guide/en/logstash/current/ls-security.html
- https://discuss.elastic.co/t/permissions-for-beats/219437/3
- https://github.com/elastic/beats/issues/10241#issuecomment-511943737