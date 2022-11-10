# nsplease

## Principe

Chaque projet a un Namespace de CI depuis lequel les workflows de CI/CD sont exécutés.

Les projets peuvent demander des déploiements qui consistent en un ou plusieurs Namespaces où pourront être exécutés des jobs de CI puis déployées des ressources.

Un Namespace de CI doit avoir tous les droits sur tous les Namespaces de tous les déploiements de son projet et sur lui-même.

Un Namespace d'un déploiement doit avoir les droits de lecture sur tous les Namespaces de ce déploiement, dont lui-même.

Le déploiement parent d'un Namespace de déploiement est noté dessus grâce à un label.

![schema du principe de fonctionnement](schema/nsplease.png "Principe de fonctionnement")

## Specs

### Procédure de base

Un Namespace `requested-ns` est créé avec le label `nsplease/deployment=project-1-deployment-1`.

Opérations à effectuer :

- **droits de lecture sur lui-même** : créer dans `requested-ns` un ServiceAccount, un Role de lecture et un RoleBinding entre les deux
- **droits de lecture par `requested-ns` sur tous les autres Namespaces du déploiement** : créer dans chaque autre Namespace un RoleBinding entre son Role de lecture et le ServiceAccount de `requested-ns`
- **droits de lecture par tous les autres Namespaces sur `requested-ns`** : créer dans `requested-ns` un RoleBinding pour chaque autre Namespace du déploiement, entre le Role de `requested-ns` et le ServiceAccount de l'autre Namespace
- **tous les droits par le Namespace de CI sur `requested-ns`** : créer dans `requested-ns` un Role accès complet et un RoleBinding vers le ServiceAccount du Namespace de CI

Si la procédure se déroule avec succès, ajouter une annotation `nsplease/state=done` sur `requested-ns`.

### Échec de la procédure

Si une des actions de la liste échoue, réessayer l'opération complète plusieurs fois en temporisant. Si la procédure reste en échec, ajouter une annotation `nsplease/state=failed` et arrêter.

Si un Namespace est modifié avec l'annotation `nsplease/state=retry`, la procédure complète est relancée.
