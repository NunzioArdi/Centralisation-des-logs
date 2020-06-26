# Configuration 1

Cette configuration rend compatible la RFC5424 (et la RFC3164) dans elasticsearch grace au filtre grok de logstash. La RFC5424 n'étant pas toujours compatible avec les vieux système, une configuration des données pour que les log utilisant l'ancienne RFC soit plus complet.

![test](config1.png?raw=true)

## Serveur rsyslog 

```
/var/log/client/$hostname/$programname_$YEAR$MONTH$DAY.log <-- log des clients
/var/log/local/programname_$YEAR$MONTH$DAY.log             <-- log du serveur
/var/log/*                                                         <-- log non syslogger
```

### Rsyslog
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
    constant(value="_")
    property(name="$YEAR")
    property(name="$MONTH")
    property(name="$DAY")
    constant(value=".log")
}

template(name=LocalFile" type="string" string="/var/log/local/%programname%%$YEAR%%$MONTH%%$DAY%_.log")
if $fromhost-ip == '127.0.0.1' then {
 action(type="omfile" dynafile="LocalFile")
 stop
}
 
*.* ?TmplMsg # toutes les Facility et toutes les Severity utilise le template ci-dessus
```



### FileBeat
Config complète.
Remplacer \<IP_ELK\> par l'ip du serveur ELK.
```yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/local/*.log
  exclude_file: ['filebeat.log$']
setup.kibana:
  host: "<IP_ELK>:5601"
output.logstash:
  # The Logstash hosts
  hosts: ["<IP_ELK>:5044"]
logging.metrics.enabled: false
```

## Client

### Rsyslog
Config complète.
Pour les ancienns version.<br>
Remplacer \<IP\> par l'ip du serveur
```
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

## rsyslog client et serveur
### Rsyslog
Peut être mis pour le client pour avoir des log formatés RFC. N'a pas d'impacte sur l'envois pour les clients et sur les anciens logs déjà écrit. Ancienne écriture.
```
#template pour log RFC3164 (pour logstash) si RFC5424 non supporter
$template logstash, "%timestamp% <%syslogfacility%.%syslogpriority%> %hostname% %programname%: %msg%\n"
$ActionFileDefaultTemplate logstash

#Utilise la RFC 5424 si possible
$ActionFileDefaultTemplate RSYSLOG_SyslogProtocol23Format
```

Pour les nouvelles version, juste changer le module et ajouter la dernière ligne
```
module(load="builtin:omfile" Template="RSYSLOG_SyslogProtocol23Format")
*.* @<IP>:514
```

### Supression de log automatique
Execute une commande quotidiennement qui supprimes les fichiers log qui ont plus de 60 jours
```
# crontab -e
0 0 * * * root find /var/log -name "*.log" -type f -mtime +60 -delete
```

## ELK
### Logstash
```
input {
  beats {
    port => 5044
    id => "beat_plugin"
  }
}
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "linux-%{+YYYY.MM.dd}"
  }
}
```

```
# 1 tags grokmatch doit apparetre, sinon ça veut dire qu'il n'est pas conforme et qu'il faut lui créer un filtre
filter {

    # pour les logs DNF
    if  "dnf" in [tags] {
        grok {
            pattern_definitions => { "SEVERITY2" => "(CRITICAL|ERROR|WARNING|INFO|DEBUG|DDEBUG|SUBDEBUG)" }
            match => [
              "message", "%{TIMESTAMP_ISO8601:ts} %{SEVERITY2:severity_text} (?<message>(.|\r|\n)*)"
            ]
            overwrite => [ "message" ]
            add_tag => ["grokmatch"]
        }
    }
    
    # RFC5424
    if "grokmatch" not in [tags] {
        grok {
            match => [
              "message", "%{SYSLOG5424LINE}"
            ]
            add_tag => ["grokmatch"]
            add_field => { "syslog_version" => "rfc5424" }
        }
    }

    # si pas RFC5424, test RFC 3164
    if "grokmatch" not in [tags] {
        grok {
            match => [
                "message", "%{SYSLOGLINE}"
            ]
            add_tag => ["grokmatch"]
            remove_tag => [ "_grokparsefailure" ]
            add_field => { "syslog_version" => "rfc3164" }
        }
    }
    
    # test non passé, le log n'est pas conforme pour l'analyse
  
  
#-    
    # mis en forme de dnf
    if "dnf" in [tags] and "_grokparsefailure" not in [tags] {
        mutate {
            add_field => { "program" => "dnf" }
            add_tag => [ "notsyslog" ]
        }

        date {
            match => [ "ts", "ISO8601" ]
            remove_field => [ "ts", "timestamp" ]
        }

         # DDEBUG, les commande utilisé apparaissent, donc severity 5 (notice)
         ruby {
             code => 's_t = event.get("severity_text")
if s_t == "CRITICAL" then
  event.set("severity", 2)
elsif s_t == "ERROR" then
  event.set("severity", 3)
elsif s_t == "WARNING" then
   event.set("severity", 4)
elsif s_t == "INFO" then
   event.set("severity", 6)
elsif s_t == "DDEBUG" then
   event.set("severity", 5)
elsif s_t == "DEBUG" then
   event.set("severity", 7)
elsif s_t == "SUBDEBUG" then
   event.set("severity", 7)
end
'
         }
    }
    
    if [syslog_version] == "rfc5424" {

        # renome les champs rfc5424 en champs plus lisible
        # STRUCTURED-DATA sera un simple string
        mutate {
            rename => {
              "syslog5424_host"  => "hostname"
              "syslog5424_app"   => "process"
              "syslog5424_msg"   => "message"
              "syslog5424_proc"  => "pid"
              "syslog5424_pri"   => "priority"
              "syslog5424_msgid" => "msgid"
              "syslog5424_sd"    => "structured_data"
            }
            remove_field => [
              "syslog5424_ver"
            ]
        }

        # ajouter les champs severity et facility
        ruby {
          code => 'event.set("severity", event.get("priority").to_i.modulo(8))'
        }
        ruby {
          code => 'event.set("facility", (event.get("priority").to_i / 8).floor)'
        }

        # la date du log sert de timestamp
        date {
            match => [ "syslog5424_ts", "ISO8601" ]
            remove_field => [ "syslog5424_ts", "timestamp" ]
      }
    }

}
```

## En plus
### Filebeat
Envois des logs dnf (yum?). Comme ces log peuvent être multiline, un patern regroupe les ligne en une seul. 
```yml
- type: log
  paths:
    - /var/log/dnf*.log
  multiline.pattern: '[\d|-]+T[\d|:]+Z\s'
  multiline.negate: true
  multiline.match: after
  tags: ["dnf"]
```

### Logstash et la rfc5424
Ce qui faudrait pour une entière compatibilité (pas pas necessaire puisque la plupard des app n'utilise pas la STRUCTURED-DATA).
Le problème a été donnée dans une issus github et n'est toujours pas règlé a cause de certains caractères qui complique le parsing (notament des `\]``\"` dans value) 
```
 STRUCTURED-DATA => [SD-ID1[@digits] name1="value" namen="value"]...[SD-IDn[@digits] name1="value" namen="value"]
   |
   V
 "sd": {
    "sd1": {
       "sd-name": "SD-ID1",
       "sd-digits: digits,
       "param": {
          "name1": "value",
           .
           .
          "namen": "value"
          }
    }
    .
    .
    "sdn": {
       "sd-name": "SD-ID",
       "sd-digits: digits,
       "param": {
          "name1": "value",
           .
           .
          "namen": "value"
          }
    }
 }
 ```
