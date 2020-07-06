# Création d'un cycle de vie d'un index (IML)
La gestion du cycle de vie des index ou Index Lifecycle Management (ILM) permet de gérer les index de leurs création, en passant par leur gestion, à leur supression.

## Info et Source
La documention sur les cycles de vide des index ce trouve [ici](https://www.elastic.co/guide/en/elasticsearch/reference/7.8/index-lifecycle-management.html)

La manipulation peut ce faire depuis l'interface kibana ou en utilisant l'API Rest (Curl ou Dev Tools de kibana)
Dans kibana, les manipulations doivent ce faire dans l'onglet *Stask Management*. Pour l'API REST, elle peut être aussi utilisé dans Kibana dans l'onglet *Dev Tools* qui dispose de l'auto-completion.

[Issues #1][i1]
## Créer une politique de cycle de vie
### Phase
Il y a 4 phases, avec la première qui est obligatoire:
- Hot: Index accessible en ecriture et lecture rapide
- Warm: Index en lecteur seul et lecture rapide
- Cold: Index en lecteur seul et lecture lente
- Delete: Supression de l'index

C'est phase servent aussi à réduire le nombre de réplique et à déplacer les shards sur des nodes moins performente pour obtimisé les performences en privilégiant les logs plus récent. 

### Rollover
Une option également important est le rolllover. (Je n'ai pas bien saisie sont l'intérêt) Il permet de recréer un index (avec un indice incrémentable). Les options de phase ne seront plus basé sur le temps à compter de la création de l'indice mais sur le rollover.

### Kibana
Rendez-vous dans *Index Lifecycle Policies* puis *Create Policy*
Il suffie de cocher les phases désiré et d'indiqué le temps voulu.

### Rest
Exemple:
```json
PUT _ilm/policy/nom-de-la-politique
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "2d"
          },
          "set_priority": {
            "priority": 0
          }
        }
      },
      "cold": {
        "min_age": "1d",
        "actions": {
          "freeze": {}
        }
      },
      "delete": {
        "min_age": "1d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

## Créer un modèle d'index
Un modèle d'index sert à attribué à un nouvelle index créé certains paramètres, notament la politique de cycle de vie utilisé ou le mapping des champs. Nous allons ici configurer l'ILM.

### Kibana
Ce rendre dans *Index Management* puis dans *Index Templates* et enfin dans *Create a template*.
1. Logistics
 - Name: Le nom du modèle
 - Index patterns: Applique ce modèle au nom d'index qui match (linux-log*)
2. Index settings

On donne le nom de la politique créé juste avant et le nom d'un alias: il dois être le même que celui du paterne.
```json
{
  "index": {
    "lifecycle": {
      "name": "nom-de-la-politique",
      "rollover_alias": "linux-log"
    }
  }
}
```
3. Mappings
Ne nous interesse pas.
4. Aliases
Ne nous interesse pas.
5. Review template
Cliquer sur *save template*.

### Rest
```json
PUT _template/nom-du-modele?include_type_name
{
  "version": 1,
  "order": 0,
  "index_patterns": [
    "linux-log*"
  ],
  "settings": {
    "index": {
      "lifecycle": {
        "name": "nom-de-la-politique",
        "rollover_alias": "linux-log"
      }
    }
  },
  "aliases": {}
}
```

## Logstash
Il faut maintenant indiqué à Logstash de créer des index en utilisant le modèle créé juste avant. `ilm_rollover_alias` dois avoir le même que celui indiqué dans le modèle.
Dans un output
```
    elasticsearch {
      manage_template => false
      hosts => ["localhost:9200"]
      ilm_rollover_alias => "linux-log"
    }
```
Les log générés auront ces noms: 
```
linux-log-2020-07-01-000001
|         |          |       
|         v          v
v         Date       Indice Rollover
Rollover alias
```

A noté que lorsque le rollover est activé, le paramètre `index` n'est plus utilisé. Ce sont les paramètres `ilm_rollover_alias` et `ilm_pattern` qui définisent le nom du modèle.


<!--
Référence
-->
[i1]: https://github.com/NunzioArdi/CNRS-stage/issues/1
