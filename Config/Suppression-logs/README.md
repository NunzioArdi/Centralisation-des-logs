# Suppression des logs

## Supression automatique
Dans le cadre du respect du RGPD, les logs ne peuvent être stockés pour une durée indéfinie et doivent être supprimés. Ci-dessous les méthodes de suppression en fonction de l'environnement.

### ELK
Voir [ILM.md](ILM.md)

### Linux
Il faut modifier la configuration rsyslog et ajouter une commande cron

#### Rsyslog
Cette configuration ajoute en plus la date du jours.

```
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

#### Cron

On éxécute une commande cron qui supprimes les fichiers log qui ont plus de n jours depuis leurs dernières modification.
```
# crontab -e
0 0 * * * root find /var/log -name "*.log" -type f -mtime +<n> -delete
```