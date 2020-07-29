
## Cryptage du trafic entre Kibana et Elasticsearch
Pour sécuriser la connection entre Elasticsearch et Kibana (et debloquer certaines fonctionnalité), il faut:
- Ajouter `xpack.security.enabled: true` dans `elasticsearch.yml`
- Activer le chiffrement http dans elasticsearch
  - Executer la commande `/usr/share/elasticsearch/bin/elasticsearch-certutil http`
  - Répondre au question. Pour faire simple, on d'indique pas de mot de passe. Pour la question des hôtes et des ip, mettre celles qui sont utilisé
  - Décompresser le fichier et suivre les instructions des fichier README des dossiers elasticsearch et kibana
  - Rédemarer les logiciels.