# CLAUDE.md — Trackeo GPS Tracking Monorepo

## Vue d'ensemble du projet

**Trackeo** est une plateforme de tracking GPS en temps réel. Elle s'appuie sur :
- **Traccar** comme serveur de collecte des positions GPS
- **NestJS** comme API backend exposant les données
- **Flutter Web (PWA)** comme frontend unique (web + mobile via navigateur)
- **PostgreSQL + TimescaleDB** pour le stockage des séries temporelles

---

## Stratégie MVP — "Local First"

Développement 100% local d'abord, déploiement VPS en fin de cycle.

### Cible frontend (en 2 phases)

| Phase | Cible | Raison |
|---|---|---|
| **MVP (maintenant)** | Flutter Web — PWA | Déploiement immédiat via URL, pas de contrainte App Store, même codebase Flutter |
| **V2 (finalité)** | Flutter Mobile — iOS & Android | App native distribuée sur les stores, même code base réutilisé à ~80% |

> ⚠️ **Conséquence pour le code** : écrire le code Flutter de façon platform-agnostic dès le départ (pas de plugins purement mobile dans le MVP). Le passage PWA → Mobile sera une adaptation, pas une réécriture.

### Décisions techniques justifiées

| Composant | Vision initiale | Choix MVP | Raison |
|---|---|---|---|
| Ingestion GPS | MQTT + HTTP custom | **Traccar** | Gère nativement des milliers de protocoles GPS binaires |
| Backend | Microservices | **NestJS monolithe modulaire** | Plus simple à gérer seul |
| Frontend | React Native + ReactJS | **Flutter Web (PWA) → Mobile** | Un seul codebase Flutter, PWA d'abord, mobile ensuite |
| Live Tracking | WebSocket temps réel | **Polling 10s → WebSocket (V2)** | Polling suffisant pour MVP, WebSocket en V2 mobile |
| Infra | Cloud AWS | **Docker sur VPS / Local** | Local First, portable, économique |

---

## Périmètre MVP (In Scope)

### ✅ Fonctionnalités incluses

1. **Suivi en temps réel** — Polling API toutes les 10s (pas WebSocket)
2. **Historique des trajets** — Affichage des points bruts reliés par une polyligne (pas d'algorithme de segmentation)
3. **Geofencing basique** — Vérification : "Le dernier point est-il hors du cercle ?"
4. **Gestion de flotte** — Liste de véhicules filtrables (statut, recherche)
5. **Authentification** — Login JWT simple

### ❌ Reporté en V2

| Fonctionnalité | Raison du report |
|---|---|
| App mobile native (iOS / Android) | Flutter Web PWA d'abord, stores ensuite |
| WebSocket temps réel | Polling 10s suffit pour MVP PWA |
| Onboarding QR Code + OTP WhatsApp | Trop complexe, admin crée manuellement |
| Mode Vol & commandes hardware | Trop risqué sans supervision humaine |
| Paiements Stripe / Mobile Money | Manuel pour MVP (activation par admin) |
| Application Installateur | Google Form ou WhatsApp à la place |
| Segmentation automatique des trajets | Points bruts suffisants pour MVP |

---

## Feuille de route (16 semaines)

### Mois 1 — Setup & Simulation
| Semaine | Objectif | Statut |
|---|---|---|
| S1 | Docker + Traccar + PostgreSQL | ✅ Fait |
| S2 | Simulation GPS (simulate.ts + Traccar Client mobile) | ✅ Fait |
| S3-S4 | API NestJS : Auth JWT + Vehicles (fleet list, polling, history) | ✅ Fait |

### Mois 2 — Frontend PWA
| Semaine | Objectif | Statut |
|---|---|---|
| S5-S6 | Init Flutter Web + flutter_map + marqueur véhicule (polling 10s) | 🔄 En cours |
| S7-S8 | Login + Fleet List + Popup détail (vitesse, batterie) | 🔲 À faire |

### Mois 3 — Fonctionnalités Métier
| Semaine | Objectif | Statut |
|---|---|---|
| S9-S10 | Historique trajet (sélecteur de date + polyligne) | 🔲 À faire |
| S11-S12 | Admin basique (créer user, lier device) + tests terrain | 🔲 À faire |

### Mois 4 — Déploiement VPS
| Semaine | Objectif | Statut |
|---|---|---|
| S13 | Acquérir VPS + domaine `trackeo.mg` + Docker sur VPS | 🔲 À faire |
| S14 | Migration code + HTTPS (SSL) | 🔲 À faire |
| S15 | Connexion GPS réel → IP publique VPS | 🔲 À faire |
| S16 | Go Live ! | 🔲 À faire |

---

## Structure du monorepo

```
trackeo/
├── apps/
│   ├── api/                   # Backend NestJS (REST API)
│   │   ├── src/
│   │   │   ├── config/        # Configuration DB, env vars
│   │   │   ├── auth/          # Module Auth (JWT login) ✅
│   │   │   ├── devices/       # Module Devices (entity, service, controller) ✅
│   │   │   ├── positions/     # Module Positions (entity, service, controller) ✅
│   │   │   ├── vehicles/      # Module Vehicles (combine devices + positions) ✅
│   │   │   └── users/         # Module Users (entity, service) ✅
│   │   ├── Dockerfile
│   │   └── package.json
│   └── mobile/                # Frontend Flutter Web (PWA)
│       └── lib/
│           ├── core/
│           │   └── network/   # Client Dio (api_client.dart)
│           └── features/
│               ├── auth/      # Login view + provider
│               ├── devices/   # Modèle, repository, providers, fleet list
│               └── map/       # Vue carte (flutter_map) + tracking temps réel
├── infra/
│   ├── postgres/
│   │   └── init.sql           # Init TimescaleDB extensions
│   └── traccar/
│       └── traccar.xml        # Config Traccar → PostgreSQL
├── scripts/
│   └── simulate.ts            # Simulateur de positions GPS
├── docker-compose.yml         # Stack complète
└── CLAUDE.md                  # Ce fichier
```

---

## Stack technique

| Couche | Technologie | Version |
|---|---|---|
| API | NestJS + TypeORM | ^10 |
| Base de données | PostgreSQL + TimescaleDB | 14+ |
| GPS Server | Traccar | latest |
| Frontend | Flutter Web (PWA) + Riverpod | 3.x |
| Carte | flutter_map (OSM) | ^6 |
| HTTP Client | Dio (polling 10s) | ^5 |
| Conteneurs | Docker Compose | v3.9 |

---

## Démarrage rapide

### 1. Lancer l'infrastructure

```bash
docker compose up -d postgres traccar
# Attendre ~30s que Traccar initialise son schéma
docker compose logs -f traccar
```

### 2. Lancer l'API NestJS (dev)

```bash
cd apps/api
cp .env.example .env
npm install
npm run start:dev
```

### 3. Simuler un véhicule GPS

```bash
cd scripts
npx ts-node simulate.ts
# Ou avec options :
DEVICE_ID=camion-01 TOTAL_POINTS=50 INTERVAL_MS=2000 npx ts-node simulate.ts
```

### 4. Lancer l'app Flutter Web (PWA)

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome          # Dev en navigateur
# Build PWA production :
flutter build web --release
```

---

## Variables d'environnement

### apps/api/.env

```
NODE_ENV=development
PORT=3000
DB_HOST=localhost       # postgres dans Docker
DB_PORT=5432
DB_USER=trackeo
DB_PASS=Password_1234
DB_NAME=traccar_db
JWT_SECRET=change_this_secret
JWT_EXPIRES_IN=7d
```

### Simulateur (scripts/simulate.ts)

```
TRACCAR_HOST=localhost   # default
TRACCAR_PORT=5055        # OsmAnd protocol
DEVICE_ID=trackeo-sim-001
INTERVAL_MS=3000
TOTAL_POINTS=30
```

---

## Ports exposés

| Service | Port | Usage |
|---|---|---|
| PostgreSQL | 5432 | Connexion directe DB |
| Traccar UI | 8082 | Interface web Traccar |
| Traccar | 5055 | Protocole OsmAnd (simulation) |
| Traccar | 5001 | GPS103/TK103 |
| Traccar | 5027 | Teltonika FMB |
| API NestJS | 3000 | REST API `/api/*` |
| Flutter Web | 8080 | PWA dev (`flutter run -d chrome`) |

---

## API Endpoints (MVP)

| Méthode | Route | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Login → retourne JWT |
| `GET` | `/api/vehicles` | Liste tous les véhicules avec statut + dernière position |
| `GET` | `/api/vehicles/:id/position` | Dernière position d'un véhicule (polling 10s) |
| `GET` | `/api/vehicles/:id/history` | Positions entre `from` et `to` (historique trajet) |

---

## Schéma de base de données

Traccar gère son propre schéma. Les tables clés :

| Table | Description |
|---|---|
| `tc_devices` | Appareils GPS enregistrés |
| `tc_positions` | Historique des positions (à convertir en hypertable) |
| `tc_users` | Utilisateurs Traccar |
| `tc_events` | Événements (geofencing, alertes…) |

### Activer TimescaleDB sur tc_positions

Après le premier démarrage de Traccar :

```sql
SELECT create_hypertable('tc_positions', 'devicetime', if_not_exists => TRUE);
```

---

## Architecture Flutter Web (PWA)

L'app suit une architecture **Feature-first + Repository pattern** :

```
feature/
├── [feature]_model.dart          # Entité (Equatable)
├── repositories/
│   └── [feature]_repository.dart # Interface + implémentation Dio
├── providers/
│   └── [feature]_provider.dart   # FutureProvider / StateProvider Riverpod
└── views/
    └── [feature]_view.dart        # ConsumerWidget
```

### Conventions

- **Models** : `Equatable`, factory `fromJson`
- **Repositories** : interface abstraite + implémentation `Remote*`
- **Providers** : `FutureProvider` pour les données async, `StateProvider` pour l'état UI
- **Views** : `ConsumerWidget`, pas de logique métier
- **Polling** : `Timer.periodic(Duration(seconds: 10), ...)` dans le provider de tracking

---

## Règles pour Claude

- **Ne pas modifier** le schéma Traccar (`synchronize: false` dans TypeORM)
- **Ne jamais** committer de credentials réels — utiliser `.env` (gitignored)
- **Toujours** passer par le `DeviceRepository` dans Flutter, pas appeler Dio directement dans les vues
- **Pas de WebSocket pour le MVP** — utiliser le polling toutes les 10s uniquement (WebSocket prévu en V2 avec l'app mobile native)
- **Pas d'algorithme de segmentation de trajets** — afficher les points bruts reliés par une polyligne
- Avant d'ajouter un nouveau protocole Traccar, vérifier qu'il n'est pas déjà activé dans `traccar.xml`
- Les migrations TypeORM sont uniquement pour les tables **propres à l'API** (pas les tables `tc_*`)

---

## Prochaine étape immédiate (S5-S6)

- [ ] Vérifier que l'app Flutter compile en mode web (`flutter run -d chrome`)
- [ ] Bottom navigation bar (5 onglets : List / Map / + / Alerts / Settings)
- [ ] Screen Fleet List (`/features/devices/views/fleet_list_view.dart`) avec polling `GET /api/vehicles`
- [ ] Screen Map (`/features/map/views/map_view.dart`) avec marqueur véhicule + polling 10s `GET /api/vehicles/:id/position`
- [ ] Intégrer login JWT dans Dio (intercepteur Bearer token)
