# Configuration 1

Cette configuration utilise la RFC5424

![test](config1.png?raw=true)

## rsyslog 

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
