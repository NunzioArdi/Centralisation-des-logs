# Agents Beats
FileBeat est un service qui va récupérer les logs d'un client et les envoyers à un serveur. Il peut les envoyer vers logstash ou Elasticsearch.

## Filebeat
Filebeat est un client qui va récupérer des fichiers de logs. Il peut être utilisé sur GNU/Linux ou Windows.

### Configuration de base
Le fichier de configuration à éditer: `/etc/filebeat/filebeat.yml`. Attention aux indentations.

#### Les entrées
Il y a 2 façons de récupérer des fichiers: les inputs et les modules.
- Les modules sont des configurations déjà faites qui récupèrent les fichiers spécifiques au module et ajoutes des champs pour simplifier l'analyse.
- Les inputs sont des configurations manuelles.

L’avantage des modules est que la configuration est déjà faites mais qu'ils sont limités si l'on veut envoyer d'autres logs.

L’avantage des entrées manuelles est que l'on peut configurer touts type de log. Mais il faut ensuite configurer les champs dans Logstash pour pouvoir les analyser. 
##### modules
[La liste des modules](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-modules.html).<br>Pour activer un module, utilisé cette commande: `# filebeat modules enables <nom du module>`. La liste des modules se trouve dans le répertoire `/etc/filebeat/module.d/`. Une fois le module activé, on peut éditer le fichier de configuration du module.

##### inputs
[Listes des entrées](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-filebeat-options.html).<br>Les entrées que l'on utilisera le plus sont de type log. Pour une entrée, on peut définir plusieurs fichiers, et configurer plusieurs paramètres comme l'ajout de tags, de champs ou la gestion des multilingues.
```
filebeat.inputs:
- type: log
  paths:
    # tous les logs du répertoire /var/log
    - /var/log/*.log
    # tous les logs qui ce trouve dans le premier dossier du répertoire /var/log
    - /var/log/*/*.log
  # ajoute à la liste des tags json, utile pour logstash et/ou kibana
  tags: ["rfc5424"]
  # Liste des fichiers à exclure en regex
  exclude_files: [ '/var/log/G.*\.log', 'messages$']
- type: log
  paths: 
    - /var/log/messages
  tags: [messages]
```
Dans cet exemple, tous les logs du dossier et du sous-dossier `/var/log` seront envoyé avec le tag `rfc5424`, excepter les fichiers commençant par la lettre `G` et le fichier `messages`.<br>La deuxième entrée enverra les logs du fichier messages sans tags.

Attention: si dans la configuration il y a plusieurs inputs et qu'un fichier peut  récupéré par les 2, un log sera envoyé en doublon.

#### Les sorties
Plusieurs sorties sont disponibles mais il ne peut en avoir d'une seule. On commente la sortie elasticsearch et on configure la sortie logstash.
```
output.logstash:
  hosts: ["<IP_L>:<PORT>"]
```

### Exemple
Une liste d'exemples est disponible dans le repo.