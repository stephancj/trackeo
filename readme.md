# Guide de Test iooeh

Ce guide vous accompagne pas à pas pour lancer et tester l'environnement de développement complet de iooeh.

## Étape 1 — Lancer l'infrastructure (Docker)

Assurez-vous que Docker Desktop est lancé sur votre Mac (attendez que l'icône baleine apparaisse dans la barre des menus), puis exécutez les commandes suivantes à la racine du projet :

```bash
cd /Users/schristian/Dev/Personals/trackeo
docker compose up -d postgres traccar
```

Attendez environ 30 secondes pour que Traccar s'initialise correctement. Vous pouvez vérifier son état avec :

```bash
docker compose logs traccar | tail -20
# Le démarrage est OK quand vous voyez la ligne : "Server startup in X ms"
```

## Étape 2 — Initialiser la base de données et le compte admin

Il faut appliquer les migrations de la base de données pour l'API et créer un premier compte administrateur.

```bash
cd apps/api
npm run migration:run
```

Ensuite, créez un compte via un appel API :

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@trackeo.mg","password":"trackeo123","name":"Admin","role":"admin"}'
```

## Étape 3 — Lancer l'API NestJS

Dans le dossier de l'API, lancez le serveur en mode développement :

```bash
cd apps/api
npm run start:dev
```

Testez que l'API répond correctement (dans un autre terminal) :

```bash
curl http://localhost:3000/api
# Vous devriez obtenir la réponse → "Hello World!"
```

## Étape 4 — Lancer le Frontend Flutter Web

Lancez l'interface utilisateur Flutter pour le web :

```bash
cd apps/mobile
flutter run -d chrome
```

Une fenêtre du navigateur Chrome s'ouvrira sur l'écran de Login. Connectez-vous avec les identifiants créés précédemment :
- **Email** : `admin@trackeo.mg`
- **Mot de passe** : `trackeo123`

## Étape 5 (Optionnel) — Simuler un GPS pour générer des trajets

Sans données de position, la liste des véhicules de l'application sera vide. Vous pouvez simuler des déplacements GPS.

### 5.1 Enregistrer le véhicule dans Traccar
Pour que le simulateur fonctionne, le véhicule doit d'abord être déclaré dans Traccar.

1. Allez sur l'interface de Traccar : [http://localhost:8082](http://localhost:8082)
2. Connectez-vous avec les identifiants par défaut de Traccar : **admin** / **admin**
3. En haut à gauche, cliquez sur le bouton **"+"** (Ajouter un appareil).
4. Remplissez les champs :
   - **Nom** : *ex: Camion Simulateur*
   - **Identifiant** : `trackeo-sim-001` *(C'est l'identifiant par défaut envoyé par le script de simulation, il faut respecter cette valeur exacte).*
5. Cliquez sur **Enregistrer**.

### 5.2 Lancer le script de simulation
Dans un nouveau terminal, depuis la racine du projet, lancez le simulateur :

```bash
cd scripts
npx ts-node simulate.ts
```

> **Note** : Le script simule un déplacement entre Paris et La Défense. Une fois cette étape passée, vous devriez voir le véhicule apparaître en ligne sur la carte de iooeh et se déplacer en temps réel ! Vous pouvez aussi personnaliser l'identifiant avec par exemple : `DEVICE_ID=mon-camion INTERVAL_MS=2000 npx ts-node simulate.ts` (n'oubliez pas de créer l'identifiant `mon-camion` dans l'interface Traccar).

---

## Liste de vérification rapide

| Vérification | Commande |
| :--- | :--- |
| **Docker tourne** | `docker compose ps` |
| **API répond** | `curl localhost:3000/api` |
| **Login fonctionne** | `curl -X POST localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@trackeo.mg","password":"trackeo123"}'` |
| **Flutter web tourne** | `flutter run -d chrome` (dans `apps/mobile`) |
