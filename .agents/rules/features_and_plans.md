# Règle : Raccordement Obligatoire des Fonctionnalités aux Plans (Entitlements)

Pour **chaque nouvelle fonctionnalité** développée sur l'application Trackeo :

1. **Visibilité & Déclaration Admin (`features`)** :
   - La fonctionnalité doit obligatoirement être déclarée dans la table `features` via une migration SQL (code unique, nom, description, catégorie, type de valeur).
   - Elle doit être visible dans l'interface d'administration sous **Fonctionnalités** (`/features`).

2. **Association aux Plans (`plan_features`)** :
   - La fonctionnalité doit être associée à chaque plan d'abonnement (`Free`, `Basic`, `Premium`) via `plan_features`.
   - Elle doit être attachable et modifiable depuis l'écran **Plans** (`/plans`) dans le back-office Admin Next.js.

3. **Contrôle d'Accès API & Client (`EntitlementsService`)** :
   - L'API NestJS doit protéger les endpoints de cette fonctionnalité en appelant `await this.entitlementsService.assertFeature(userId, 'code_feature')`.
   - L'application Flutter PWA doit vérifier l'activation de la fonctionnalité via `rights.has('code_feature')` avant d'afficher les boutons ou écrans associés.
