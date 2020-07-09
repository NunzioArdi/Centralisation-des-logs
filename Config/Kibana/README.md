# Kibana
Kibana est un outils de visualisation / gestion de la base de données Elasticsearch.

Pour accéder à l'interface web, il suffit de mettr l'ip:port inscrit dans le fichier de configuration.
La page *Select your space* permet de choisir un espace de travail personnalisé. On selectionne *Default*

## Voir les logs
Avec la configuration de base, des logs sont envoyer à logstash qui les envoyent à elasticsearch en créant un index.
L'objectif et de voir les logs de cette index.

Dans le menu à gauche: 

*Stack Management*->*Index Management*: Normalment il devrait y avoir 1 ou plusieurs index.
*Stack Management*->*Index Patterns*->*Create index pattern*: le nom du paterne selectionnera tout les index avec le même nom
    *Next step*->Dans la liste déroulante, selectionné *@timestamp*->*Create index pattern*.
Ensuite on retourne au menu de gauche: *Discover* et les logs apparaiterons.

Explication:
Un index peut être séparer en plusieur index (1 index par jour par exemple). L'index pattern de kibana va permettre de créer un index nous permettant de tous les voir.<br>
@timestamp est un champs contenant une date. On le selectionne pour que les logs soit "trié par date en fonction de ce champs". De base, il s'agit de la date à laquelle Elasticsearch à reçu le log et non la date de création. Il peut être bien avoir d'autres champs de type timestamps (il devrons avoir un autre nom).<br>
La section *Discover* permet de voir, filtrer, examiner les logs collecter.