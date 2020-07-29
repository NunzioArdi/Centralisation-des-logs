# Rsyslog

> Rsyslog est un logiciel libre transférant les messages des journaux d'événements sur un réseau IP. Rsyslog implémente le protocole basique syslog. Il présente la particularité d'en étendre les fonctionnalités en permettant, notamment, de filtrer sur des champs, de filtrer à l'aide d'expressions régulières et l'utilisation du protocole TCP de la couche transport. 

La dernière version de syslog: [RFC5424](https://tools.ietf.org/html/rfc5424).<br>
La documentation officiel sur [Readthedocs](https://rsyslog.readthedocs.io/en/latest/index.html).

Le fichier de conf comporte 3 parties:
- les modules
- les directives
- les règles

Note: le fichier est lu dans l'ordre donc attention à l'ordre dans lesquels ont écrit les règles.

## Syslog
4 choses importantes à savoir sur l'importance d'un log:
- La `priority` d'un log est définie par la `facility` (catégorie) et la `severity` (graviter)
- Les facility définissent le type de message (0-23)
- Les severity définissent le niveau gravité de l'évènement (0-7)
- La priority est calaculée avec: `8 * facility + severity`
Le tableau les listant (code et mot-clef) est disponible [ici](https://en.wikipedia.org/wiki/Syslog#Facility)

## Configuration
### Les modules
Un module active une fonctionnalité, généralement une entrer ou une sortie. Dans la partie d'installation, on a activé le module d'input UDP pour le serveur. On remarque aussi que pour les versions plus récentes, le module `imjournal` sert à importer les logs de systemd.

### Les directives et les règles
L'enregistrement des logs passent par 2 étapes: 
- on définit quoi prendre (facility et severity)
- on définit où et comment l'enregistrer (template)
Cela donne `facility.level template1;template2`

Prenons cette exemple  `*.info;mail.none;authpriv.none;cron.none                /var/log/messages`<br>
1. Entrée
    - Toutes les facility ayant pour severity info(5) ou moins
    - Ne pas inclure les facility mail, authpriv et cron
2. Sortie
    - Emplacement statique /var/log/messages
    - Pas de syntaxe indiqué, utilise celle définit par défaut

#### Template
Les modèles définissent où et comment seront enregistrer les logs. Ils peuvent utiliser des propriétés comme le nom du programme, qui sont [lister dans la documentation](https://rsyslog.readthedocs.io/en/latest/configuration/properties.html "liste des propriétés")
 

Le premier donne l'emplacement. Il peut être statique ou dynamique. Pour définir un emplacement dynamique, il faut créer le modèle. Par exemple, pour le serveur, si l'on veut enregistrer tous les logs dans ce format `/var/log/clients/<FROMHOST-IP>/<PROGRAMNAME>.log` pour séparer les logs des différents serveurs, on doit rajouter d’abord rajouter la template, supprimer toutes les autres règles et puis indiquées dans la règle son nom.
<br>Nouvelle syntaxe
```
template(name="splitHostname" type="list" {
	constant(value="/var/log/clients/")
	property(name="hostname")
	constant(value="/")
	property(name="programname" SecurePath="replace")
	constant(value=".log")
}
*.* ?RemoteLogs
```
Ancienne syntaxe
```
$template splitHostname,"/var/log/remote2/%FROMHOST-IP%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
```
Le point d'interrogation indique que la template est dynamique.

Le deuxième définit la façon dont sera écrit le log dans les fichiers. Si il n'est pas indiqué, c'est la directive globale qui est utilisée.
<br>Nouvelle syntaxe
```
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
```
Ancienne syntaxe
```
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format
```
Ici, on indique d'écrire les logs avec la syntaxe de la RFC5424. Une liste de modèle comme celui-ce est disponible dans la documentation.

Pour changer le modèle par défaut ou pour en appliquer un de façon spécifique.
<br>Nouvelle syntaxe
```
template(name="test" type="string" string="<%PRI%>%TIMESTAMP:::date-rfc3339% %msg%\n")
*.* ?RemoteLogs;test
```
Ancienne syntaxe
```
$template test,"<%PRI%>%TIMESTAMP:::date-rfc3339% %msg%\n"
*.* ?RemoteLogs;test
```

#### Plus loins
Si l'on veut par exemple séparer les logs des clients du serveur, il suffit de la rajouter avant la règle principale celle-ci
<br>Nouvelle syntaxe
```
template(name=LocalFile" type="string" string="/var/log/local/%programname%.log")
if $fromhost-ip == '127.0.0.1' then {
  action(type="omfile" dynafile="LocalFile")
  stop
}
*.* ?modeleFichier
```
Ancienne syntaxe
```
```
Les fichiers locaux seront enregistrés selon le modèle dynamique `LocalFile`. `stop` (ou `& ~` pour l'ancienne syntaxe) signifie que le log s'arrête ici et ne continue pas les autres règles.

## A voir
*Ce que je n'ai pas ecrit mais qui est intéressant a voir*
- [Module input file](https://rsyslog.readthedocs.io/en/latest/configuration/modules/imfile.html). Permet d'ajouter des fichiers au log (comme les log d'un site apache) qui ne passe pas par syslog. Cela résoudrait peu être le problème de ces logs pour pouvoir tout centraliser.

- Pour les logs windows:
  - rsyslog propose un client windows mais il semble [payant](https://www.rsyslog.com/windows-agent/edition-comparison/)
  - L'agent Winlogbeat mais l'envoie est limité à Elasticsearch ou Logstash. Comme  plusieurs host peuvent être indiquer dans la sortie logstash, il serait possible d'installer logstash sur le serveur rsys et d'utiliser le plugin d'output [syslog](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-syslog.html) pour l'envoyer à rsyslog. L'aventage est que winlogbeat peut toujours envoyer ces log au serveur ELK.
  - [Eventsys]( https://code.google.com/archive/p/eventlog-to-syslog/downloads)
  - [nxlog](https://nxlog.co/) 