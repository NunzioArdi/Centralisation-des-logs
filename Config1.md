# Configuration 1

Cette configuration rend compatible la RFC5424 et la RFC3164 dans elasticsearch grace au filtre grok de logstash. La dernière RFC n'étant pas toujours compatible avec les vieux système, une configuration des données pour que les log utilisant l'ancienne RFC soit plus complet.

Les configurations si dessous sont les fichiers complet sans les commentaires.

![test](config1.png?raw=true)

## Serveur rsyslog 

### Serveur
```
module(load="imuxsock" SysSock.Use="off")
module(load="imjournal" StateFile="imjournal.state")
module(load="imudp")
input(type="imudp" port="514")
 
global(workDirectory="/var/lib/rsyslog")
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
include(file="/etc/rsyslog.d/*.conf" mode="optional")
 
template(name="TmplMsg" type="list") {
    constant(value="/var/log/clients/")
    property(name="hostname")
    constant(value="/")
    property(name="programname" SecurePath="replace")
    constant(value=".log")
}
 
*.* ?TmplMsg
```

### Client
Pour les ancienns version.
Remplacer \<IP\> par l'ip du serveur
```conf
*. * @<IP>:514

$ModLoad imuxsock.so
$ModLoad imklog.so
 
$template logstash, "%timestamp% <%syslogfacility%.%syslogpriority%> %hostname% %programname%: %msg%\n"
 
#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat #Format par défaut
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format #Utilise la RFC 5424 si possible
#$ActionFileDefaultTemplate logstash #Utilise la template au dessus pour enregistrer les facility et les priority (ne le fais pas de base) et rendre compatible avec logstash
 
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 *
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
 
*.* @<IP>:514
```
Pour les nouvelles version, juste changer le module et ajouter la dernière ligne
```
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
*.* @<IP>:514
```

## Client beat

### FileBeat sur rsyslog
Remplacer \<HOSTNAME\> par le hostname du serveur rsyslog.<br>
Remplacer \<IP ELK\> par l'ip du serveur ELK.

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
  host: "<IP ELK>:5601"
output.logstash:
  # The Logstash hosts
  hosts: ["<IP ELK>:5044"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
logging.metrics.enabled: false
monitoring.enabled: false
```
