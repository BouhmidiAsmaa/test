🎯 Objectif
Implémenter un contrôle côté serveur (plugin Dataverse) pour empêcher la modification des enregistrements de type Contact  Actionnaires (i.e. lorsque fond_numeroactionnaire est renseigné), tout en permettant certaines exceptions contrôlées et les comptes de service.

Principe de la solution
La solution repose sur un plugin Dataverse enregistré sur l’événement Update de l’entité Contact, qui :

Identifie si le contact est synchronisé BOF

Vérifie si l’utilisateur est un compte de service

Compare les champs modifiés avec une liste blanche configurable

Bloque ou autorise l’opération

Composants
1. Plugin Dataverse
Message : Update

Primary Entity : contact

Stage : PreOperation (recommandé pour bloquer avant écriture)

Mode : Synchrone

2. Variable d’environnement
Nom : fon_contactactionnaire_champs_autorises

Type : Texte

Valeur : Liste des noms logiques de champs, séparés par des virgules
Exemple : 



fond_birthdate,emailaddress1,telephone1
3. Rôles de sécurité (exception)
Les utilisateurs ayant au moins un des rôles suivants sont exemptés du contrôle :

Fondaction - Service Account BOF

Fondaction - Service Account Dataverse

Flux d’exécution du plugin
Étape 1 – Validation du contexte
Vérifier que le message est Update

Vérifier que la cible (Target) contient des attributs

Étape 2 – Identification du contact Actionnaire
Lire fond_numeroactionnaire

Depuis :

PreImage (recommandé)

ou via récupération si absent

✅ Si vide → autoriser (aucun blocage)

❌ Si renseigné → appliquer les règles suivantes

Étape 3 – Vérification du rôle utilisateur
Récupérer les rôles de l’utilisateur (context.InitiatingUserId)

Si l’utilisateur possède l’un des rôles suivants :

Fondaction - Service Account BOF

Fondaction - Service Account Dataverse

✅ Autoriser toutes les modifications
→ Sortie immédiate du plugin

Étape 4 – Chargement de la configuration
Lire la variable d’environnement : fon_contactactionnaire_champs_autorises

Parser la liste :



string[] allowedFields = value.Split(',');
Étape 5 – Analyse des champs modifiés
Lire les attributs présents dans Target.Attributes

Vérifier :



Tous les champs modifiés ⊆ allowedFields ?
Cas 1 – Tous les champs sont autorisés ✅
→ Autoriser la mise à jour

Cas 2 – Au moins un champ non autorisé ❌
→ Bloquer la mise à jour

Étape 6 – Blocage
Lever une exception métier :

 

throw new InvalidPluginExecutionException(

    "Ce contact est un actionnaire et ne peut pas être modifié."

);

Bonnes pratiques
✅ Utiliser PreImage
Inclure :



fond_numeroactionnaire
✅ Performance
Ne pas faire de Retrieve inutile

Cache possible des variables d’environnement (optionnel)

✅ Sécurité
Validation 100 % côté serveur

Protection contre API, imports, intégrations

✅ Maintenabilité
Liste des champs autorisés configurable sans code

Rôles facilement extensibles
