# Suppression des logs

## Supression automatique
Dans le cadre du respect du RGPD, les logs ne peuvent être stockés pour une durée indéfinie et doivent être supprimés. Ci-dessous les méthodes de suppression en fonction de l'environnement.

### ELK
Voir [ILM.md](ILM.md)

### Linux

On éxécute une commande cron qui supprimes les fichiers log qui ont plus de n jours depuis leurs dernières modification.
```
# crontab -e
0 0 * * * root find /var/log -name "*.log" -type f -mtime +<n> -delete
```