# Sécurité

*Note: La sécurité est une option x-pack mais la plupart des options sont inclues dans la licence basique*

## Connection par mot de passe
Pour pouvoir accéder à l'interface kibana et que pour les programmes ELK utilisent une connexion.
Après cette configuration, des options `Security` vont apparaitre dans ` Stack Management`

1. Elasticsearch
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

2. Kibana
    - Modifier `/etc/kibana/kibana.yml`
```yaml
elasticsearch:
  username: "kibana_system"
  password: "*"
```
    - Lancer Kibana
    - Allez sur l'interface web de kibana et utiliser les identifiants `Elastic` `<mot_de_passe>`