# CNRS-stage
## Rsyslog
### Intro

Un seul fichier de configuration devra être modifier, pour le serveur comme pour le client : `/etc/rsyslog.conf`<br>
Les fichiers de log seront stockés dans le répertoire `/var/log`.<br>
La configuration serveur présenté utilise la nouvelle notation de rsyslog (≥v7). Néanmoins l’ancienne notation reste compatible; tout du moins pour les template.

[RFC5424](https://tools.ietf.org/html/rfc5424)<br>
[Documentation officiel](https://www.rsyslog.com/doc/master/index.html)

### Configuration du serveur

La configuration de rsyslog permet de définir la façon dont les fichiers seront stockés et comment les messages de log seront mis en forme. La première étape est de configurer le rsyslog pour qu’il devienne un serveur :
-	Utilise le port 514 en UDP pour recevoir les logs.
Dé commenter les 2 lignes 
```
module(load="imudp")
input(type="imudp" port "514")
```

-	Si SELinux est activé<br>
`# semanage port -a -t syslogd_port_t -p udp 514`

-	Si le pare-feu est activé 
`# firewall-cmd --permanent --add-port=514/udp`<br>
`# firewall-cmd –reload`

Le serveur peut maintenant recevoir des logs depuis le port 514 en UDP. 

Vient ensuite la configuration de stockage des logs. Les règles que nous allons créer seront appliqué pour les logs des clients
et ceux du serveur lui-même.<br>
Une règle est définit par `facility.level [?]template1;template2`.<br>
Un modèle peut être un chemin `/var/log/message` ou le nom d’un modèle. Le `?` indique un modèle de fichier dynamique.
De nombreux [exemples](https://rsyslog-doc.readthedocs.io/en/latest/configuration/examples.html) avec leurs explications sont
disponibles dans la documentation.<br>
2 modèles peuvent par exemple être appliqué pour définir l’emplacement du fichier et la façon dont le message sera écrit dans
le fichier.
Un modèle est défini par `template(parameters) { list-descriptions }`

Pour avoir une structure de type `/var/log/clients/<NOM HOST>/<PROGRAMME>.log`, il suffit de rajouter au fichier de configuration
```
template(name="modeleFichier" type="list" {
	constant(value="/var/log/clients/")
	property(name="hostname")
	constant(value="/")
	property(name="programname" SecurePath="replace")
	constant(value=".log")
}
```
 

Ensuite on ajoute cette ligne qui indique que tous les logs utiliseront le model modeleFichier
```
*.* ?modeleFichier
```
