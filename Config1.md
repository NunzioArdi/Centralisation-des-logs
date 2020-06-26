# Configuration 1

Cette configuration rend compatible la RFC5424 (et la RFC3164) dans elasticsearch grace au filtre grok de logstash. La RFC5424 n'étant pas toujours compatible avec les vieux système, une configuration des données pour que les log utilisant l'ancienne RFC soit plus complet.

![test](config1.png?raw=true)

Config complète en diff

## Serveur rsyslog 

### Serveur
Config complète
```
module(load="imuxsock" SysSock.Use="off")
module(load="imjournal" StateFile="imjournal.state")
module(load="imudp")
input(type="imudp" port="514")
 
global(workDirectory="/var/lib/rsyslog")
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format") # RFC 5424
include(file="/etc/rsyslog.d/*.conf" mode="optional")
 
template(name="TmplMsg" type="list") { # /var/log/clients/%HOSTNAME%/%PROGRAMNAME%.log
   constant(value="/var/log/clients/")
    property(name="hostname")
    constant(value="/")
    property(name="programname" SecurePath="replace")
    constant(value=".log")
}

template(name=LocalFile" type="string" string="/var/log/local/%programname%.log")
if $fromhost-ip == '127.0.0.1' then {
 action(type="omfile" dynafile="LocalFile")
 stop
}
 
*.* ?TmplMsg # toutes les Facility et toutes les Severity utilise le template ci-dessus
```

### Client
Config complète.
Pour les ancienns version.<br>
Remplacer \<IP\> par l'ip du serveur
```
*. * @<IP>:514

$ModLoad imuxsock.so
$ModLoad imklog.so
 
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 *
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
 
*.* @<IP>:514 # toutes les Facility et toutes les Severity sont envoyés à l'ip (en copie)
```
Pour les nouvelles version, juste changer le module et ajouter la dernière ligne
```
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
*.* @<IP>:514
```

### Les 2
Peut être mis pour le client pour avoir des log formatés RFC. N'a pas d'impacte sur l'envois pour les clients et sur les anciens logs déjà écrit. Ancienne écriture.
```
#template pour log RFC3164 (pour logstash) si RFC5424 non supporter
$template logstash, "%timestamp% <%syslogfacility%.%syslogpriority%> %hostname% %programname%: %msg%\n"
$ActionFileDefaultTemplate logstash

#Utilise la RFC 5424 si possible
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format

```

## Supression de log automatique
### Serveur rsyslog
Execute une commande quotidiennement qui supprimes les fichiers log qui ont plus de 60 jours
```
# crontab -e
0 0 * * * root find /var/log -name "*.log" -type f -mtime +60 -delete
```

## Client beat

### FileBeat sur rsyslog
Config complète.
Remplacer \<HOSTNAME\> par le hostname du serveur rsyslog.<br>
Remplacer \<IP_ELK\> par l'ip du serveur ELK.

```yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/clients/<HOSTNAME>/*.log
    - /var/log/*.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "<IP_ELK>:5601"
output.logstash:
  # The Logstash hosts
  hosts: ["<IP_ELK>:5044"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
logging.metrics.enabled: false
monitoring.enabled: false
```
