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
| Interface Admin | Intégrée au frontend | **Next.js (Reporté)** | L'interface d'administration back-office sera développée en Next.js plus tard |
| Live Tracking | WebSocket temps réel | **Polling 10s → WebSocket (V2)** | Polling suffisant pour MVP, WebSocket en V2 mobile |
| Infra | Cloud AWS | **Docker sur VPS / Local** | Local First, portable, économique |

---

## Catalogue des fonctionnalités

### MVP (0–6 mois)

#### ✅ Suivi en temps réel (Live Tracking)
- Carte avec marqueur véhicule mis à jour toutes les 10s (polling)
- Vitesse, batterie, force signal, statut affiché
- Statut "offline" si aucune mise à jour après 30s
- **V2** : Lien de suivi partageable sans login (lien expirant)
- **V2** : WebSocket temps réel (polling suffisant pour MVP PWA)

#### ✅ Historique des trajets (Raw History)
- Sélecteur de date (from/to)
- Appel `GET /api/vehicles/:id/history?from=&to=`
- Polyligne sur flutter_map (`PolylineLayer`)
- Marqueurs départ / arrivée
- Stats trip (distance Haversine, durée, vitesse max)
- ⚠️ Pas d'algorithme de segmentation — points bruts reliés par polyligne

#### 🔲 Geofencing basique
- Création de zone (cercle, rayon 100m–5km)
- Vérification : "Le dernier point est-il hors du cercle ?"
- Alerte entrée/sortie avec debounce (N=3 pings consécutifs ou distance >50m sur 30s)
- Notification push + WhatsApp
- PostGIS `ST_Contains` pour test point-dans-polygone

#### 🔲 Onboarding & Activation appareil (QR / OTP)
- Scan QR (contient `device_id`) → OTP WhatsApp/SMS → liaison device/compte
- Fallback OTP si QR indisponible
- OTP expire en 10 min ; rate-limit ; token chiffré
- **MVP simplifié** : admin crée manuellement via Traccar UI — onboarding QR/OTP en V2

#### 🔲 Gestion des alertes & support
- File d'alertes + actions owner (Share Live Link, Call Support)
- Ticket support créé automatiquement
- Escalade automatique après timeout configurable (défaut 10 min) si owner ne répond pas
- Canaux : push, WhatsApp, Messenger, SMS

#### 🔲 Mode Vol & Récupération
- Owner signale vol → fréquence reporting augmentée (5s si supporté)
- Ticket support créé + notification partenaires
- Annulation possible dans la minute (faux positif)
- **Reporté** : commande hardware d'immobilisation → V2+ (supervision humaine obligatoire)

#### 🔲 Flow Installation & Photos Installateur
- Installateur : VIN + ≥2 photos + confirmation placement
- **MVP** : Google Form ou WhatsApp à la place — flow applicatif en V2

#### 🔲 Gestion de compte & Abonnement (basique)
- Plans, période d'essai, facturation Stripe (carte) puis mobile money local
- **MVP** : activation manuelle par admin

---

### Near-term (6–18 mois)

#### 🔲 Trips & Trip Aggregator
- Worker de segmentation des trajets depuis `tc_positions`
- Table `trips` dédiée pour requêtes rapides
- Critères de segmentation : vitesse > seuil OU mouvement > distance ET gap < seuil
- Lecture des trajets paginée + polyline GeoJSON
- Playback trajet sur carte

#### 🔲 Rapports Distance (complet)
- Totaux journaliers/hebdo/mensuels par device depuis table `trips`
- Export CSV / PDF
- `GET /devices/:id/reports/distance?start=&end=&interval=daily|weekly|monthly`
- Agrégation Timescale `time_bucket()` pour performances

#### 🔲 Télémétrie Carburant
- Champs `fuel_pct` / `fuel_v` dans la télémétrie (entrée analogique ou OBD-II)
- Lissage / calibration tension→pourcentage
- Jauge carburant + graphe historique
- Alerte niveau bas + alerte chute soudaine (vol)
- Consommation L/100km par trajet si `tank_capacity_liters` renseigné

#### 🔲 Module Livraison / Collecte (basique)
- Flux chauffeur/marchand/client pour livraison colis
- Statuts : `accepted → arrived_pickup → picked_up → in_transit → delivered`
- Photo preuve de livraison (POD)
- Lien de tracking live pour le client (sans login)
- Dispatch simple : nearest driver naïf (distance)

#### 🔲 Gestion de flotte B2B & Dashboard web
- Multi-véhicules, groupes, assignation chauffeur, rapports
- Import CSV (jusqu'à 1 000 devices)
- RBAC pour membres de l'équipe
- Rapports planifiés + exports batch

#### 🔲 API Partenaires & Webhooks (sociétés de sécurité)
- Partenaires enregistrent des webhooks, s'abonnent aux alertes
- POST HMAC-signé ; retries exponentiels
- Partenaire peut claim/ack les alertes
- Scopes limités : `location:read`, `alerts:subscribe`
- Consentement owner requis pour partage historique

#### 🔲 OTA Firmware Management
- Hébergement firmware + déploiement canary (1–5 devices)
- Monitoring erreurs + rollback si taux d'échec > seuil
- MQTT `devices/{id}/ota` avec url + checksum SHA256

---

### Future (18+ mois)

#### 🔲 Immobilisateur à distance / Contrôle véhicule
- Coupure démarreur à distance (soumis à cadre légal)
- Multi-factor confirmation + interlock fail-safe + audit log
- Human-in-the-loop obligatoire

#### 🔲 Analytics avancées & IA
- Détection d'anomalies, maintenance prédictive, scoring comportement chauffeur
- Opt-in pour données d'entraînement

---

## Feuille de route (16 semaines MVP)

### Mois 1 — Setup & Simulation
| Semaine | Objectif | Statut |
|---|---|---|
| S1 | Docker + Traccar + PostgreSQL | ✅ Fait |
| S2 | Simulation GPS (simulate.ts + Traccar Client mobile) | ✅ Fait |
| S3-S4 | API NestJS : Auth JWT + Vehicles (fleet list, polling, history) | ✅ Fait |

### Mois 2 — Frontend PWA
| Semaine | Objectif | Statut |
|---|---|---|
| S5-S6 | Init Flutter Web + flutter_map + marqueur véhicule (polling 10s) | ✅ Fait |
| S7-S8 | Login + Fleet List + Popup détail (vitesse, batterie) | ✅ Fait |

### Mois 3 — Fonctionnalités Métier
| Semaine | Objectif | Statut |
|---|---|---|
| S9-S10 | Historique trajet (sélecteur de date + polyligne + stats) | ✅ Fait |
| S11-S12 | Init DB device_assignments + Tests terrain (Admin Next.js reporté) | 🔄 En cours |

### Mois 4 — Déploiement VPS & Tests Terrain
| Semaine | Objectif | Statut |
|---|---|---|
| S13 | Réserver VPS + nom de domaine `trackeo.mg` | 🔲 À faire |
| S14 | Docker sur VPS + Configurer HTTPS (Let's Encrypt SSL) | 🔲 À faire |
| S15 | Tracker GPS matériel réel → Configuration IP / Port VPS | 🔲 À faire |
| S16 | Tests sur route complets + Lancement "Go Live" | 🔲 À faire |

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
│           │   ├── network/   # Client Dio (api_client.dart)
│           │   ├── navigation/ # AppShell, activeTabProvider
│           │   └── theme/     # AppTheme, AppColors
│           └── features/
│               ├── auth/      # Login view + provider ✅
│               ├── vehicles/  # Modèle, repository, providers, fleet list ✅
│               ├── map/       # Vue carte (flutter_map) + tracking temps réel ✅
│               └── history/   # Historique trajet + stats ✅
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

## API Endpoints

### MVP (implémentés)

| Méthode | Route | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Login → retourne JWT |
| `GET` | `/api/vehicles` | Liste tous les véhicules avec statut + dernière position |
| `GET` | `/api/vehicles/:id/position` | Dernière position d'un véhicule (polling 10s) |
| `GET` | `/api/vehicles/:id/history` | Positions entre `from` et `to` (historique trajet) |

### Near-term (à implémenter)

| Méthode | Route | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Inscription + provisionnement device |
| `POST` | `/api/provision/request-otp` | Demande OTP pour activation device |
| `POST` | `/api/provision/claim` | Valide OTP + lie device au compte |
| `GET` | `/api/vehicles/:id/reports/distance` | Totaux distance par période (`?start=&end=&interval=daily\|weekly\|monthly`) |
| `GET` | `/api/vehicles/:id/trips` | Liste des trajets segmentés (`?start=&end=&page=`) |
| `POST` | `/api/geofences` | Créer une geofence (cercle ou polygone) |
| `GET` | `/api/geofences` | Liste des geofences de l'utilisateur |
| `DELETE` | `/api/geofences/:id` | Supprimer une geofence |
| `POST` | `/api/devices/:id/theft` | Déclencher le mode récupération vol |
| `GET` | `/api/alerts` | File d'alertes de l'utilisateur |
| `POST` | `/api/alerts/:id/escalate` | Escalader une alerte au partenaire |

---

## Schéma de base de données

### Tables Traccar (ne pas modifier — `synchronize: false`)

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

### Tables propres à l'API (migrations TypeORM)

```sql
-- Assignation des devices (Lié propriétaire Trackeo <-> Device Traccar)
CREATE TABLE device_assignments (
  id SERIAL PRIMARY KEY,
  device_id INTEGER NOT NULL UNIQUE,
  user_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trajets segmentés (Near-term)
CREATE TABLE trips (
  id uuid PRIMARY KEY,
  device_id text NOT NULL,
  start_ts timestamptz,
  end_ts timestamptz,
  distance_m double precision,
  duration_s integer,
  geom geometry(LineString, 4326),
  created_at timestamptz DEFAULT now()
);

-- Geofences
CREATE TABLE geofences (
  id uuid PRIMARY KEY,
  owner_id uuid,
  device_id text,
  geom geometry,
  name text,
  radius_m integer,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Alertes
CREATE TABLE alerts (
  id uuid PRIMARY KEY,
  device_id text,
  owner_id uuid,
  type text,           -- 'geofence_exit', 'geofence_enter', 'theft', 'low_battery'
  status text,         -- 'open', 'acked', 'escalated', 'resolved'
  created_at timestamptz DEFAULT now(),
  handled_by uuid
);

-- Télémétrie carburant (Near-term)
CREATE TABLE device_fuel_readings (
  id bigserial PRIMARY KEY,
  device_id text,
  ts timestamptz,
  fuel_pct numeric,
  fuel_v numeric,
  raw jsonb
);

-- Livraisons (Near-term)
CREATE TABLE deliveries (
  id uuid PRIMARY KEY,
  merchant_id uuid,
  customer_id uuid,
  driver_id uuid,
  pickup_lat double precision,
  pickup_lon double precision,
  dropoff_lat double precision,
  dropoff_lon double precision,
  status varchar,      -- 'pending', 'accepted', 'picked_up', 'in_transit', 'delivered'
  eta timestamptz,
  amount_cents integer,
  pod_photos jsonb,
  created_at timestamptz DEFAULT now()
);

-- Chauffeurs (Near-term)
CREATE TABLE drivers (
  id uuid PRIMARY KEY,
  user_id uuid,
  vehicle_device_id text,
  status varchar,
  created_at timestamptz DEFAULT now()
);

-- Installations (Near-term)
CREATE TABLE installations (
  id uuid PRIMARY KEY,
  device_id text,
  installer_id uuid,
  photos jsonb,
  vin text,
  installed_at timestamptz DEFAULT now()
);

-- Abonnements
CREATE TABLE subscriptions (
  id uuid PRIMARY KEY,
  user_id uuid,
  plan text,
  status text,
  next_billing_date timestamptz
);
```

---

## Schéma de télémétrie (canonical)

```json
{
  "device_id": "DEV123456",
  "ts": 1700000000,
  "lat": -18.8792,
  "lon": 47.5079,
  "speed_kmh": 0,
  "heading": 180,
  "battery_pct": 78,
  "gsm_signal": 12,
  "event": "heartbeat",
  "seq": 12345,
  "firmware": "v1.2.3",
  "fuel_pct": 57.3,
  "fuel_v": 2.34,
  "odometer_m": 1234567
}
```

> `ts` en epoch seconds UTC. `seq` monotone par device (le serveur rejette les doublons). `fuel_pct` / `fuel_v` optionnels (selon matériel). `odometer_m` préférable à Haversine pour distance cumulative précise.

---

## Workflow de notification & escalade

1. Alerte créée → push + message WhatsApp (template) à l'owner (avec actions : Share Live Link, Call Support)
2. Si aucun accusé de l'owner en `EscalationTimeout` (défaut 10 min) → notif webhook partenaire + WhatsApp
3. Ticket support créé immédiatement ; support peut demander consentement owner pour partager position avec police → lien éphémère + log
4. Partenaire claim l'alerte : `open → in_progress → resolved`
5. Toutes les étapes sont auditées

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
- **Providers** : `AsyncNotifierProvider` pour les données async avec polling, `FutureProvider` pour les données one-shot, `StateProvider` pour l'état UI
- **Views** : `ConsumerWidget`, pas de logique métier
- **Polling** : `Timer.periodic(Duration(seconds: 10), ...)` dans `AsyncNotifier._refresh()` — ne jamais passer par `AsyncLoading` pour éviter le flash des marqueurs
- **valueOrNull** : utiliser `vehiclesAsync.valueOrNull ?? []` pour les données affichées sur la carte

---

## Règles pour Claude

- **Ne pas modifier** le schéma Traccar (`synchronize: false` dans TypeORM)
- **Ne jamais** committer de credentials réels — utiliser `.env` (gitignored)
- **Toujours** passer par le `VehicleRepository` / `DeviceRepository` dans Flutter, pas appeler Dio directement dans les vues
- **Pas de WebSocket pour le MVP** — utiliser le polling toutes les 10s uniquement (WebSocket prévu en V2 avec l'app mobile native)
- **Pas d'algorithme de segmentation de trajets dans le MVP** — afficher les points bruts reliés par une polyligne (segmentation = Near-term avec table `trips`)
- Avant d'ajouter un nouveau protocole Traccar, vérifier qu'il n'est pas déjà activé dans `traccar.xml`
- Les migrations TypeORM sont uniquement pour les tables **propres à l'API** (pas les tables `tc_*`)
- **selectedVehicle** : stocker uniquement l'id dans `selectedVehicleIdProvider`, dériver le `Vehicle?` via `Provider` depuis la liste live — toujours fraîche
- **withOpacity** déprécié depuis Flutter 3.38 → utiliser `withValues(alpha: x)`
- **dart:math** : `pi` est disponible via import transitif de `flutter_map`/`latlong2` — importer explicitement seulement si `sin`, `cos`, `sqrt`, `atan2` sont utilisés

---

## Checklist avancement

### ✅ Fait (S1–S10)
- [x] Docker + Traccar + PostgreSQL
- [x] Simulation GPS (`simulate.ts`)
- [x] API NestJS : Auth JWT, Vehicles (fleet list, polling, history)
- [x] Flutter Web PWA : Login, Bottom Nav, Fleet List, Carte OSM + marqueurs + polling 10s
- [x] Statut véhicule (online=Moving / idle / offline) basé sur le champ `status` Traccar
- [x] Bouton recentrer sur la carte
- [x] Design Figma : header logo+bell, search bar, filter chips, vehicle card LIVE badge
- [x] Fix marqueurs : `AsyncNotifier._refresh()` sans flash + `valueOrNull` pattern
- [x] Fix popup : flag `_markerJustTapped` pour conflit tap marker/map
- [x] Screen Historique : sélecteur de date, polyligne, stats (distance/durée/vitesse max), timeline
- [x] Navigation liste → carte : tap véhicule bascule sur l'onglet Map

### 🔲 À faire (S11-S12)
- [x] Migration SQL pour `device_assignments` exécutée (lie un device Traccar à un user Trackeo)
- [ ] Interface Admin Web (à développer ultérieurement avec **Next.js**)
- [ ] **Geofencing basique** :
  - API (NestJS) : Créer les endpoints `POST /api/geofences` et `GET /api/geofences`.
  - API (NestJS) : Service (Cron/Event) pour vérifier par rapport à la localisation (`ST_Contains`).
  - Mobile (Flutter) : UI pour dessiner une geofence circulaire sur la map et recevoir l'alerte.

### 🔲 Prochaines Étapes Immédiates (Déploiement VPS & Setup Prod)
Maintenant que le MVP (S1-S10) est opérationnel, l'objectif est de le mettre en ligne de manière sécurisée pour de vrais tests.

1. **Infrastructure Cloud**
   - [ ] Louer un serveur VPS (ex: Hetzner, OVH, DigitalOcean).
   - [ ] Réserver le nom de domaine `trackeo.mg`.
   - [ ] Faire pointer le sous-domaine `api.trackeo.mg` et Traccar vers l'IP du VPS.

2. **Déploiement & Sécurité**
   - [ ] Installer Docker & Docker Compose sur le VPS.
   - [ ] Mettre en place un proxy inversé (ex: Nginx Proxy Manager ou Traefik) pour gérer les certificats SSL automatistés (HTTPS).
   - [ ] Mettre en place un script de CI/CD basique (Github Actions ou hooks git) pour mettre à jour l'API et la web app.

3. **Intégration Hardware (Tests Terrain)**
   - [ ] Obtenir un traceur GPS physique réel (Teltonika, Coban, Sinotrack, etc.).
   - [ ] Configurer le traceur (par SMS) pour lui donner l'IP publique du VPS, le bon port de Traccar correspondant au protocole, et l'APN de la carte SIM malgache.
   - [ ] Créer l'identifiant du tracker (IMEI) dans l'interface de Trackeo.
   - [ ] Mettre le tracker dans une voiture réelle à Antananarivo et s'assurer que sa route s'affiche sans accroc.
