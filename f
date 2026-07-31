Analyse des options — Extensibilité du champ Sujet (Dynamics 365 Customer Service)
Option 1 — Table standard partagée entre toutes les équipes

Description
Les sujets des nouvelles équipes (Employeurs, Partenaires) sont ajoutés directement dans la table Sujet standard, aux côtés de ceux du CRA. Aucune distinction technique entre les branches de sujets ; le contrôle d'arborescence standard reste utilisé par tous.

Risque
Moyen. Tous les sujets sont visibles par toutes les équipes — un agent peut voir et sélectionner un sujet destiné à une autre équipe, ce qui fausse potentiellement le routage automatique et les statistiques.

Effort
Faible. Aucune nouvelle table, aucun nouveau contrôle, aucune modification du modèle de sécurité.

Maintenance
Faible à court terme, mais dette de données croissante : l'arborescence devient volumineuse et confuse à mesure que les équipes s'ajoutent, sans mécanisme natif de filtrage.

Complexité
Faible. Aucune logique additionnelle à concevoir.

Risque de régression
Nul pour le CRA — les processus, le routage et les automatismes existants ne sont pas touchés.

Option 2 — Table 100 % personnalisée pour toutes les équipes

Description
Abandon complet de l'entité Sujet standard, pour toutes les équipes y compris le CRA, au profit d'une table custom avec un contrôle d'interface reconstruit (composant PCF) pour reproduire l'arborescence.

Risque
Très élevé. Reconstruction complète du routage, des automatismes et du formulaire ; toute erreur affecte directement le CRA, dont les processus actuels fonctionnent bien.

Effort
Très élevé. Développement du contrôle d'arborescence, migration des données historiques, réécriture des règles de routage, des automatismes, et potentiellement des liens avec la Base de connaissances.

Maintenance
Élevée au départ (stabilisation post-migration), mais plus stable une fois en place, puisque tout est sous contrôle interne.

Complexité
Très élevée. Touche simultanément la donnée, l'interface, la sécurité, le routage et l'intégration avec les autres modules Customer Service.

Risque de régression
Élevé, particulièrement pour le CRA, qui n'était pas visé initialement par le besoin mais dont la configuration est entièrement reconstruite.

Option 3 — Approche hybride (CRA standard, autres équipes séparées)

Description
Le CRA continue d'utiliser la table Sujet standard sans aucun changement. Les nouvelles équipes (Employeurs, Partenaires) obtiennent une solution distincte (table ou mécanisme séparé), indépendante du Sujet standard.

Risque
Faible à moyen. Aucun risque pour le CRA ; le risque se limite aux nouvelles équipes, notamment la perte d'accès à des fonctionnalités natives liées au Sujet standard (Base de connaissances, suggestions automatiques).

Effort
Moyen. Limité au périmètre des nouvelles équipes, livrable de façon incrémentale, équipe par équipe.

Maintenance
Moyenne. Deux modèles de données distincts à maintenir en parallèle, avec un risque de duplication de sujets similaires si la gouvernance des données n'est pas encadrée.

Complexité
Moyenne. Deux systèmes à documenter, deux logiques de routage à gérer séparément.

Risque de régression
Nul pour le CRA — configuration intacte. Aucun risque de régression pour les nouvelles équipes puisqu'elles partent d'une base neuve.

Option 4 — Filtrage applicatif sur la table standard (contrôle personnalisé, table inchangée)

Description
La table Sujet standard reste unique pour toutes les équipes. Un champ personnalisé (ex. « Équipe ») est ajouté pour qualifier chaque sujet. L'affichage est ensuite filtré selon l'équipe de l'utilisateur via un composant personnalisé (PCF) ou un script de filtrage sur le champ — sans toucher à la donnée elle-même, au routage ni aux automatismes.

Note : la table Sujet est une entité organisationnelle (sans champ Propriétaire), donc la sécurité native basée sur l'unité d'affaires ou la propriété ne s'applique pas ici. Le filtrage doit être géré au niveau applicatif, pas au niveau de la sécurité Dataverse.

Risque
Faible à moyen. Résout directement le problème de visibilité croisée, mais dépend d'un composant custom dont le comportement doit être validé sur tous les points d'usage du champ (formulaire, vues, mobile).

Effort
Moyen. Ajout d'un champ, développement d'un composant de filtrage ou d'un script, tests sur l'ensemble des surfaces où le Sujet est utilisé.

Maintenance
Moyenne. Un seul modèle de données à maintenir, mais un composant custom à faire évoluer lors des mises à jour de plateforme (dépendance technique à surveiller).

Complexité
Moyenne. Le filtrage doit être répliqué partout où le champ Sujet apparaît, pas seulement sur le formulaire principal.

Risque de régression
Faible pour le CRA — la donnée et le routage restent inchangés ; seul l'affichage est modifié. Un test de non-régression sur le contrôle standard est néanmoins requis pour confirmer que le comportement d'affichage actuel du CRA n'est pas altéré par le nouveau composant.
