# nsplease

## Principe

Chaque projet a un Namespace de CI depuis lequel les pipelines de CI/CD sont exécutés.

### Point d'entrée rbac (petite contextualisation)
En amont de nsplease, un `utilisateur` (ou un workflow) est membre d'un `projet`.

L'appartenance d'un `utilisateur` à un `projet` est garantis soit par `nsplease`, soit par rancher (soit les deux).

Lorsque cette appartenance est gérée par `nsplease`, cela est géré directement via les RBAC de kubernetes et un accès à un `namespace` initial détermine l'accès au `namespaces` suivants, depuis l'intérieur même de ce `namespace`. Appelons le `ci-namespace` pour plus de clareté.

La convention de nommage du `ci-namespace` permet d'en déterminer l'accès par un `projet` auquel il correspond.

L'accès initial au `ci-namespace` du projet est accordé par un service tiers de webhook (en l'occurence c'est le webhook de kontinuous).

C'est le service de webhook qui garantis l'appartenance à un projet (via un token par exemple, c'est le cas pour celui de kontinuous) et qui autorise le déploiement d'un `pipeline` dans le `namespace` de CI.

Le `pipeline` est un job kubernetes dont le manifest est prédéfini par le service de webhook, il hérite des droits accordé au `serviceaccount` présent dans le `namespace`.

### Namespace
Les projets peuvent demander des namespaces où pourront être définits des ressources kubernetes, comprenant de deployments, jobs, statefullset, secret, configmaps etc...

### Namespace group
Les namespaces peuvent partager leurs accès avec d'autres namespaces appartenants au même projet, en utilisant des `namespace-group`.

Un Namespace de CI doit avoir tous les droits sur tous les Namespaces de son projet et sur lui-même.

Un Namespace appartenant à un `namespace-group` doit avoir les droits de lecture sur tous les Namespaces de ce `namespace-group`, dont lui-même.

Le `namespace-group` d'un Namespace est noté dessus grâce à un label.

![schema du principe de fonctionnement](schema/nsplease.png "Principe de fonctionnement")

## Specs

### Procédure de base

Un Namespace `requested-ns` est créé avec le label `nsplease/namespace-group=project-1-deployment-1`.

Opérations à effectuer :

- **droits de lecture sur lui-même** : créer dans `requested-ns` un ServiceAccount, un Role de lecture et un RoleBinding entre les deux
- **droits de lecture par `requested-ns` sur tous les autres Namespaces du `namespace-group`** : créer dans chaque autre Namespace un RoleBinding entre son Role de lecture et le ServiceAccount de `requested-ns`
- **droits de lecture par tous les autres Namespaces sur `requested-ns`** : créer dans `requested-ns` un RoleBinding pour chaque autre Namespace du `namespace-group`, entre le Role de `requested-ns` et le ServiceAccount de l'autre Namespace
- **tous les droits par le Namespace de CI sur `requested-ns`** : créer dans `requested-ns` un Role accès complet et un RoleBinding vers le ServiceAccount du Namespace de CI

Si la procédure se déroule avec succès, ajouter une annotation `nsplease/state=done` sur `requested-ns`.

### Échec de la procédure

Si une des actions de la liste échoue, réessayer l'opération complète plusieurs fois en temporisant. Si la procédure reste en échec, ajouter une annotation `nsplease/state=failed` et arrêter.

Si un Namespace est modifié avec l'annotation `nsplease/state=retry`, la procédure complète est relancée.
