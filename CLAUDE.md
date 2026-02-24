# CLAUDE.md — Trackeo GPS Tracking Monorepo

## Vue d'ensemble du projet

**Trackeo** est une plateforme de tracking GPS en temps réel. Elle s'appuie sur :
- **Traccar** comme serveur de collecte des positions GPS
- **NestJS** comme API backend exposant les données
- **Flutter** comme application mobile de visualisation
- **PostgreSQL + TimescaleDB** pour le stockage des séries temporelles

---

## Structure du monorepo

```
trackeo/
├── apps/
│   ├── api/                   # Backend NestJS (REST API)
│   │   ├── src/
│   │   │   ├── config/        # Configuration DB, env vars
│   │   │   ├── devices/       # Module Devices (entity, service, controller)
│   │   │   └── positions/     # Module Positions (à créer)
│   │   ├── Dockerfile
│   │   └── package.json
│   └── mobile/                # Frontend Flutter
│       └── lib/
│           ├── core/
│           │   └── network/   # Client Dio (api_client.dart)
│           └── features/
│               ├── devices/   # Modèle, repository, providers
│               └── map/       # Vue carte (flutter_map)
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

| Couche      | Technologie                | Version  |
|-------------|----------------------------|----------|
| API         | NestJS + TypeORM           | ^10      |
| Base de données | PostgreSQL + TimescaleDB | 14+   |
| GPS Server  | Traccar                    | latest   |
| Mobile      | Flutter + Riverpod         | 3.x      |
| Carte       | flutter_map (OSM)          | ^6       |
| HTTP Client | Dio                        | ^5       |
| Conteneurs  | Docker Compose             | v3.9     |

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

### 4. Lancer l'app Flutter

```bash
cd apps/mobile
flutter pub get
flutter run
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

| Service    | Port  | Usage                          |
|------------|-------|--------------------------------|
| PostgreSQL | 5432  | Connexion directe DB           |
| Traccar UI | 8082  | Interface web Traccar          |
| Traccar    | 5055  | Protocole OsmAnd (simulation)  |
| Traccar    | 5001  | GPS103/TK103                   |
| Traccar    | 5027  | Teltonika FMB                  |
| API NestJS | 3000  | REST API `/api/*`              |

---

## Schéma de base de données

Traccar gère son propre schéma. Les tables clés :

| Table           | Description                              |
|-----------------|------------------------------------------|
| `tc_devices`    | Appareils GPS enregistrés                |
| `tc_positions`  | Historique des positions (à convertir en hypertable) |
| `tc_users`      | Utilisateurs Traccar                     |
| `tc_events`     | Événements (geofencing, alertes…)        |

### Activer TimescaleDB sur tc_positions

Après le premier démarrage de Traccar :

```sql
SELECT create_hypertable('tc_positions', 'devicetime', if_not_exists => TRUE);
```

---

## Architecture Flutter (Mobile)

L'app suit une architecture **Feature-first + Repository pattern** :

```
feature/
├── device_model.dart          # Entité (Equatable)
├── repositories/
│   └── device_repository.dart # Interface + implémentation Dio
├── providers/
│   └── devices_provider.dart  # FutureProvider Riverpod
└── views/
    └── [feature]_view.dart    # ConsumerWidget
```

### Conventions

- **Models** : `Equatable`, factory `fromJson`
- **Repositories** : interface abstraite + implémentation `Remote*`
- **Providers** : `FutureProvider` pour les données async, `StateProvider` pour l'état UI
- **Views** : `ConsumerWidget`, pas de logique métier

---

## Règles pour Claude

- **Ne pas modifier** le schéma Traccar (`synchronize: false` dans TypeORM)
- **Ne jamais** committer de credentials réels — utiliser `.env` (gitignored)
- **Toujours** passer par le `DeviceRepository` dans Flutter, pas appeler Dio directement dans les vues
- Avant d'ajouter un nouveau protocole Traccar, vérifier qu'il n'est pas déjà activé dans `traccar.xml`
- Les migrations TypeORM sont uniquement pour les tables **propres à l'API** (pas les tables `tc_*`)

---

## Prochaines étapes suggérées

- [ ] Module `positions` dans l'API (lire `tc_positions` avec pagination)
- [ ] WebSocket NestJS → Flutter pour les mises à jour temps réel
- [ ] Activer la hypertable TimescaleDB sur `tc_positions`
- [ ] Geofencing : créer des zones dans Traccar et les exposer via l'API
- [ ] Authentification JWT sur l'API NestJS
- [ ] CI/CD GitHub Actions (lint, test, docker build)
