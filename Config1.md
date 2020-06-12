# Configuration 1

Cette configuration utilise la RFC5424

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
Ligne à ajouter à la fin du document. Remplacer \<IP\> par l'ip du serveur
```conf
*. * @<IP>:514
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
