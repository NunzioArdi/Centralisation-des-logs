# CNRS-stage
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
De nombreux [exemples](https://rsyslog-doc.readthedocs.io/en/latest/configuration/examples.html) avec leurs explications sont
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
La [liste des propriétées](https://rsyslog.readthedocs.io/en/latest/configuration/properties.html) est disponible dans la documentation.

Ensuite on ajoute cette ligne qui indique que tous les logs utiliseront le model modeleFichier
```
*.* ?modeleFichier
```

 ### Configuration client

Définir l’adresse du serveur et le protocole
```
*.*  @<IP>:<PORT>
```
`@` signifie que l'envois ce fais en UDP. Pour envoyer en TCP, en mettre 2

### RFC
De base, les logs ne sont pas enregistrés selon la RCF 5424 ou même l'ancienne RFC 3164: les facility et les severity ne sont pas écrites: `TIMESTAMP_RFC3164 HOSTNAME PROGRAMNAME[PID]: MSG`. Pour utilisé la nouvelle RFC, il faut modifier le paramettre d'écriture par défaut.
```
#Pour les anciens format
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format

# Pour les nouveau format
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
```

### Plus loins
La configuration peu allez encore plus loin. Par exemple, on peut spécifier pour le serveur de séparer ces logs de ceux des clients
```
template(name=LocalFile" type="string" string="/var/log/local/%programname%.log")
if $fromhost-ip == '127.0.0.1' then {
  action(type="omfile" dynafile="LocalFile")
  stop
}
*.* ?modeleFichier
```
Les fichiers locaux seront enregistrer celon le modèle dynamique `LocalFile`. `stop` signifie que le log s'arrête ici et ne continue pas les autres règles.


## FileBeat

### Intro
FileBeat est un agent qui va lire les logs et les envoyers à un serveur. Il peut les envoyers vers logstash ou directement vers Elasticsearch. Il comprend en plus des modules qui contiennes des règles déjà faites pour certain type de logs. Mais nous n'allons pas les utiliser.

Le fichier de configuration à éditer: `/etc/filebeat/filebeat.yml`. Attention au indentation.

### Config

Dans la section inputs ce trouve une ligne paths avec des tirets. On peut ajouter autant répertoire que l'on veux. La recherche de fichier ne va pas dans les sous-repertoires.
```yml
filebeat.inputs:
- type: log
  paths:
    # tous les logs du répertoire /var/log
    - /var/log/*.log
    # tous les logs qui ce trouve dans le premier dossier du répertoire /var/log
    - /var/log/*/*.log
  
  # Liste des fichiers à exlure en regex
  exclude_files: [ '/var/log/G[A-Za-z0-9]*/.*\.log', '.']
```
Ensuite on configure la section kibana, avec l'adresse ip sur lequel il est installé
```yml
setup.kibana
  host: "<IP_K>:5601"
```
Enfin on configure l'output. Il ne peut en avoir qu'un seul.
```yml
output.logstash:
  hosts: ["<IP_L>:5044"]
```