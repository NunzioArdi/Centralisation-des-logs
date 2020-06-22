# Sauvegarde et analyse de log
Afin d'éviter des problèmes (notamment avec logstash), il est mieux de désactivé SELinux 
## Rsyslog
### Intro

Un seul fichier de configuration devra être modifié, pour le serveur comme pour le client : `/etc/rsyslog.conf`<br>
Les fichiers de logs seront stockés dans le répertoire `/var/log`.<br>
La configuration serveur présenté utilise la nouvelle notation de rsyslog (≥v7). Néanmoins l’ancienne notation reste compatible; tout du moins pour les templates.

[RFC5424](https://tools.ietf.org/html/rfc5424)<br>
[Documentation officiel](https://www.rsyslog.com/doc/master/index.html)

### Configuration du serveur

La configuration de rsyslog permet de définir la façon dont les fichiers seront stockés et comment les messages de log seront mis en forme. La première étape est de configurer rsyslog pour qu’il puisse recevoir des logs externes :
- Utilise le port 514 en UDP pour recevoir les logs.
Décommenter les 2 lignes 
```
module(load="imudp")
input(type="imudp" port "514")
```

- Si SELinux est activé<br>
`# semanage port -a -t syslogd_port_t -p udp 514`

- Si le pare-feu est activé<br>
`# firewall-cmd --permanent --add-port=514/udp`<br>
`# firewall-cmd –reload`

Le serveur peut maintenant recevoir des logs syslog depuis le port 514 en UDP. 

Vient ensuite la configuration de stockage des logs. Les règles que nous allons créer seront appliquées pour les logs des clients
et ceux du serveur lui-même.<br>
Une règle est définie par `facility.level [?]template1;template2`.<br>
Un modèle peut être un chemin `/var/log/message` ou le nom d’un modèle. Le `?` indique un modèle de fichier dynamique.
De nombreux [exemples](https://rsyslog-doc.readthedocs.io/en/latest/configuration/examples.html "exemples de configurations") avec leurs explications sont
disponibles dans la documentation.<br>
Deux modèles peuvent par exemple être appliqués pour définir l’emplacement du fichier et la façon dont le message sera écrit dans le fichier.
Un modèle est défini par `template(parameters) { list-descriptions }`

Pour avoir une structure de type `/var/log/clients/<NOM HOST>/<PROGRAMME>.log`, il suffit de rajouter au fichier de configuration ce modèle:
```
template(name="modeleFichier" type="list" {
	constant(value="/var/log/clients/")
	property(name="hostname")
	constant(value="/")
	property(name="programname" SecurePath="replace")
	constant(value=".log")
}
```
La [liste des propriétés](https://rsyslog.readthedocs.io/en/latest/configuration/properties.html) est disponible dans la documentation.

Ensuite on ajoute cette ligne qui indique que tous les logs utiliseront le model modeleFichier:
```
*.* ?modeleFichier
```

 ### Configuration client

Rajouter cette ligne à la fin du fichier, définir l’adresse du serveur, le port (514) et le protocole
```
*.*  @<IP>:<PORT>
```
`@` signifie que l'envois ce fais en UDP. Pour envoyer en TCP, mettre `@@`

A noter que c'est le serveur qui reçois  les logs qui définit la façon dont ils seront écrits.

### RFC
De base, les logs ne sont pas enregistrés selon la RCF 5424 ou même l'ancienne RFC 3164: les facility et les severity ne sont pas écrites: `TIMESTAMP_RFC3164 HOSTNAME PROGRAMNAME[PID]: MSG`. Pour utilisé la nouvelle RFC, et avoir un message de cette forme `<PRI>VERSION TIMESTAMP_RFC5424 HOSTNAME PROGRAMNAME PROCID MSGID STRUCTURED-DATA MSG`,  il faut modifier le paramètre d'écriture par défaut.
```
#Pour les anciens format
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format

# Pour les nouveau format
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
```
En générale, les nouveaux logs ressembleront à ça : `<13>1 2020-06-21T14:55:01.044793+02:00 rsysmachine root 5487 - - un message ecrit par la commande logger`
### Plus loin
La configuration peu allez encore plus loin. Par exemple, on peut spécifier pour le serveur de séparer ces logs de ceux des clients.
```
template(name=LocalFile" type="string" string="/var/log/local/%programname%.log")
if $fromhost-ip == '127.0.0.1' then {
  action(type="omfile" dynafile="LocalFile")
  stop
}
*.* ?modeleFichier
```
Les fichiers locaux seront enregistrés selon le modèle dynamique `LocalFile`. `stop` (ou `& ~`) signifie que le log s'arrête ici et ne continue pas les autres règles.
Pour que cette règle puisse bien fonctionner, il faut la mettre avant les autres règles.

## ELK
La suite elastic comprend de nombreux logiciels: 
- Elasticsearch pour stocker les logs dans une base de données non relationnel
- Kibana qui sert d'interface complète à Elasticsearch
- Logstash qui sert à récupérer les logs , appliqué des filtres et les envois à une base de données
- Beat(FileBeat, WinLogBeat...) qui sont des clients qui envoie des logs
Leur configuration pour fonctionner est assez simple mais peut être poussée assez loin. La plupart peuvent être indépendant mais sont faits pour pouvoir fonctionner ensemble.

Nous allons configurer un nouveau serveur dédier à ELK, puis nous enverrons les logs avec les clients beat que nous installerons sur les clients classiques et le serveur rsyslog.

### Elasticsearch
#### Intro
ElasticSearch est un moteur distribué de stockage, de recherche et d'analyse de contenu. [<sup>1</sup>](https://juvenal-chokogoue.developpez.com/tutoriels/elasticsearch-sgbd-nosql "ref1") . Il dispose d'une API permettant de faire des requêtes  HTTP (GET, POST, DELETE...). C'est grâce à cela que Kibana permet d'intéragir avec Elasticsearch.

#### Configuration
`/etc/elasticsearch/elasticsearch.yml`
- La configuration suivante ne permet d'accéder à l'API que en local pour éviter que les utilisateurs du réseau puissent accéder à l'API.
```yml
network.host: localhost
http.port: 9200
#discovery.seed_hosts: ["localhost"] #à mettre si network.host est sur une ip local ou autre
```

- Si le pare-feu est activé<br>
`# firewall-cmd --permanent --add-port=9200/tcp`<br>
`# firewall-cmd –reload`

### Kibana
#### Intro
Kibana sert d'interface web pour intéragir avec la base de données Elasticsearch. Il dispose également d'une API HTTP.
#### Configuration
`/etc/kibana/kibana.yml`
- <IP_E> peut très bien être localhost
```yml
server.port: 5601
server.host: <IP> #donne accès
elasticsearch.host: ["<IP_E>:<PORT_E>"]
```
- Si le pare-feu est activé<br>
`# firewall-cmd --permanent --add-port=5601/tcp`<br>
`# firewall-cmd –reload`

### Logstash
#### Intro
Logstash est un logiciel qui va servir à collecter, analyser et envoyer les logs. 
#### Configuration
La configuration de logstash ce fait en créant des fichiers .conf dans le dossier `/etc/logstash/conf.d/`. La configuration se fait en 3 parties:
- **input**: L'entrée permet à Logstash de lire une source spécifique d'événements.
- **filter**: Il effectue un traitement intermédiaire sur un événement. Les filtres sont souvent appliqués de manière conditionnelle en fonction des caractéristiques de l'événement.
- **output**: La sortie envoie des données d'événements vers une destination particulière. Les sorties constituent l'étape finale du pipeline d'événements.

Chaque partie est configurable avec des modules (la liste et leurs paramètres sont dans la documentation [input](https://www.elastic.co/guide/en/logstash/current/input-plugins.html), [output](https://www.elastic.co/guide/en/logstash/current/output-plugins.html), [filter](https://www.elastic.co/guide/en/logstash/current/filter-plugins.html)).

```
input {
  beats {
    port => 5044
  }
}
```
On utilise le module d'entrer beats pour que les logiciels comme filebeat ou winlogbeats puissent envoyer leurs données vers logstash.

```
output {
  elasticsearch {
    hosts => ["localhost:9200"]
  }
}
```
On utilise le module de sortie elasticsearch pour envoyer les données récupérées par Logstash vers une instance de elasticsearch.
```
filter {
    grok {
      break_on_match => true
      match => [ 
        "message", "%{SYSLOG5424LINE}",
        "message", "%{SYSLOGLINE}"
      ]
    }
    
    if "rfc5424" in [tags] {
        ruby {
            code => ' event.set('severity', (event.get("syslog5424_pri").to_i).modulo(8))'
        }
        ruby {
            code => 'event.set("facility",(event.get("syslog5424_pri").to_i).floor))"
        }
        mutate {
            remove_field => [ "syslog5424_pri" ]
        }
    }
}
```
Cette exemple n'est pas concret mais sert d'exemple. On utilise ici 3 modules: grok, ruby et mutate. <br>
Grok analyser un texte arbitraire et le structure. Il utilise des paternes comme `SYSLOG5424LINE` qui utilise des règles regex. [Liste des paternes](https://grokdebug.herokuapp.com/patterns). Si un log passe un paterne, il sera structuré et chaque donnée sera attribuée à un paramètre. Par exemple:
```
Jun 30 22:45:01 ubuntu dhclient: bound to 192.168.0.1 -- renewal...
match avec %{SYSLOGLINE} et donne
{
  "timestamp": [
    [
      "Jun 30 22:45:01"
    ]
  ],
  "logsource": [
    [
      "ubuntu"
    ]
  ],
  "HOSTNAME": [
    [
      "ubuntu"
    ]
  ],
  "program": [
    [
      "dhclient"
    ]
  ],
  "pid": [
    [
      null
    ]
  ],
  "message": [
    [
      "bound to 192.168.0.1 -- renewal..."
    ]
  ]
}
```
Ensuite on regarde si dans le tableau `[tags]` ce trouve la valeur `rfc5424` (que l'on peut ajouter avec beats). 
On exécute ensuite un code ruby qui va calculer la severity et la facility et ajouter un couple json `"severity: 5, facility: 4` à la sortie.
On supprime de la sortie json `syslog5424_pri: 154`, créer par grok.

### FileBeat
#### Intro
FileBeat est un agent qui va lire les logs et les envoyer à un serveur. Il peut les envoyer vers logstash ou directement vers Elasticsearch. Il comprend en plus des modules qui contiennes des règles déjà faites pour certain type de logs.

Le fichier de configuration à éditer: `/etc/filebeat/filebeat.yml`. Attention aux indentations.

#### Config

Dans la section inputs se trouve une ligne paths avec des tirets. On peut ajouter autant répertoire que l'on veut. La recherche de fichiers ne va pas dans les sous-répertoires.
```yml
filebeat.inputs:
- type: log
  paths:
    # tous les logs du répertoire /var/log
    - /var/log/*.log
    # tous les logs qui ce trouve dans le premier dossier du répertoire /var/log
    - /var/log/*/*.log
  # ajoute à la liste des tags json, utile pour logstash et/ou kibana
  tags: ["rfc5424"]
  # Liste des fichiers à exclure  en regex
  exclude_files: [ '/var/log/G[A-Za-z0-9]*/.*\.log', '.']
```
Ensuite on configure la section kibana, avec l'adresse ip sur lequel il est installé
```yml
setup.kibana
  host: "<IP_K>:5601"
```
Enfin on configure l'output. Il ne peut en avoir qu'un seul. On commente l'output de elasticsearch et on décommente celui de logstash avec:
```yml
output.logstash:
  hosts: ["<IP_L>:5044"]
```
On exécute cette commande
```cmd
# filebeat setup --dashboards
```
