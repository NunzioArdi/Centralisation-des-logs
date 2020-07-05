# Agents Beats
FileBeat est un service qui va récupérer les logs d'un client et les envoyers à un serveur. Il peut les envoyer vers logstash ou Elasticsearch.

## Filebeat
Filebeat est un client qui va récupérer des fichiers de log. Il peut être utilisé sur GNU/Linux ou Windows.

### Configuration
Le fichier de configuration à éditer: `/etc/filebeat/filebeat.yml`. Attention aux indentations.

#### Les entrées
Il y a 2 façons de récupérer des fichiers: les inputs et les modules.
- Les modules sont des configurations déjà faites qui récupère les fichiers spécifiques au module et ajoutes des champs pour simplifier l'analyse.
- Les inputes sont des configurations manuel

L'aventage des modules est que la confiurations est déjà faites mais qu'ils sont limité si l'on veux envoyer d'autres logs. 

L'aventage des entrées manuels est que l'on peut configurer touts type de log. Mais il faut ensuite configurer les champs dans logstash pour pouvoir les analyser. 

##### modules
[La liste des modules](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-modules.html).<br>Pour activer un module, utilisé cette commande: `# filebeat modules enables <nom du module>`. La liste des mdolues ce trouve dans le répertoire `/etc/filebeat/module.d/`. Une fois le module activer, on peut édité le fichier de configuration du module.

##### inputs
[Listes des entrées](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-filebeat-options.html).<br>
Les entrées que l'on utilisera le plus sont de type log. Pour une entrée, on peut définir plusieurs fichiers, et modifier des paramètres.
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
  exclude_files: [ '/var/log/G[A-Za-z0-9]*/.*\.log', 'messages$']
- type: log
  paths: 
    - /var/log/messages
  tags: [messages]
```
Dans cette exemples, tous les logs du dossier et du sous dossier `/var/log` seront envoyer avec le tags `rfc5424`, exepter les fichier commencant par la lettre `G` et le fichier `messages`.<br> La deuxième entré envéra les logs du fichier messages sans tags.

Attention: si dans la configuration il y a plusieurs inputs et d'un fichier peut être récupérer par les 2, un log sera envoyer en doublon. 

#### Les sorties
Plusieurs sortie sont disponibles mais il ne peut en avoir d'une seul. On commente la sortie elasticsearch et on configure la sortie logstash.
```
output.logstash:
  hosts: ["<IP_L>:<PORT>"]
```

### Exemple
Une listes d'exemple est disponible dans le repo
