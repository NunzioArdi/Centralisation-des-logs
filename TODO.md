# A faire
La liste des choses que je n'ai pas pu finir.

- FileBeat
  - dnf
    - Ajouter Filtre pour exclure les logs de debug
- Elasticsearch
  - Mapping
    - Je l'ai utilisé a plusieur reprise mais jamais expliquer comment ça marche et pourquoi l'utiliser
    - Permet d'attribuer a des champs un type (text par defaut). Mieux pour le stockage, permet de faire des visualisations
    - Essayer de respecter le mapping  définit dans l'[ECS](https://www.elastic.co/guide/en/ecs/master/index.html) (Elastic Common Schema) dans tout les filtres logstash: le nom des champs et le type d'info qui est ecrit 
    (severity: 5 deviendrait log.severity: INFO (ou Informationnal) 
- Kibana
  - Observability
    - Je n'avais pas encore regardé cette partie mais elle semble bien pour utiliser d'autre option d'Elasticsearch et de Kibana (notament les alertes)
  - Alerting
    - Il falais pour l'activer ajouter des options de sécuriter dans Elasticsearch et Kibana, avec des certificats de sécurité, mais je n'arrive pas à les ajouter pour les agents Beat et Logstash
  - Dashboard
    - permet de visualisé les logs dans des tableau, graphiques, ect
 - Beat
   - Importation des dashboards dans kibana
   - importation des mapping, des ILM dans Elastic
 - Cisco
   - Cisco Aironet 1700 (et Catalyst)
     - les logs ne correspondent pas entièrement au format de la doc mais mais ce qui en sort est différent, ne correspond à rien.
