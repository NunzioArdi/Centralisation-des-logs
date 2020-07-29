*Brouillon*
## L'observabiliter
*Note: brouillon*
### Logs
Ces logs seront stocker dans l'index `filebeat-<VERSION>-<DATE>-<ROLLOVER>`
### Metric
Pour ajouter des données metric, il faut installer l'agent Beat Metricbeat.
```
# metricbeat modules enable <nom_module>
```
On va tester avec les modules `elasticsearch-xpack`, `logstash-xpack`, et `system`.<br>
Modifier si necessaire l'host dans les fichiers de configuration des modules `/etc/metricbeat/module.d/<nom_module>`.<br>
On configure l'output sur elasticsearch.

Ces logs seront stocker dans l'index `metricbeat-<VERSION>-<DATE>-<ROLLOVER>`

### APM
### Uptime