/**
 * simulate.ts — Simulateur GPS réaliste pour iooeh (Antananarivo)
 *
 * Trajet : Analakely → Antanimena → Ankorondrano → Ivandry → RN1 → Ambohidratrimo
 * Distance approximative : ~18 km
 * Durée simulée : ~35 min de conduite réelle
 * Points GPS : ~160 (envoyés toutes les 3s par défaut)
 *
 * Usage :
 *   npx ts-node scripts/simulate.ts
 *   DEVICE_ID=taxi-001 INTERVAL_MS=2000 npx ts-node scripts/simulate.ts
 */

import http from 'http';

// ─── Configuration ────────────────────────────────────────────────────────────

const CONFIG = {
  traccarHost: process.env.TRACCAR_HOST ?? 'localhost',
  traccarPort: parseInt(process.env.TRACCAR_PORT ?? '5055', 10),
  deviceId:    process.env.DEVICE_ID    ?? 'tana-sim-001',
  intervalMs:  parseInt(process.env.INTERVAL_MS ?? '3000', 10),
  altitude:    1280, // Altitude moyenne d'Antananarivo (m)
};

// ─── Définition des segments ──────────────────────────────────────────────────
//
// Chaque segment représente un tronçon de route avec son profil de vitesse.
// speedMin / speedMax en km/h — la vitesse est interpolée progressivement.
// stopBefore : si true, le véhicule s'arrête (v=0) 3 points avant la fin du segment.
//
// Coordonnées validées sur OpenStreetMap pour Antananarivo.

interface Segment {
  name: string;
  waypoints: [number, number][];
  speedMin: number;
  speedMax: number;
  points: number;       // nombre de points GPS à générer pour ce segment
  stopBefore?: boolean; // feu rouge / carrefour à l'arrivée
}

const SEGMENTS: Segment[] = [
  // ── 1. Analakely — départ en ville dense ─────────────────────────────────
  {
    name: 'Analakely (marché central)',
    waypoints: [
      [-18.9137, 47.5255],
      [-18.9120, 47.5262],
      [-18.9105, 47.5268],
    ],
    speedMin: 4, speedMax: 12,
    points: 10,
    stopBefore: true,
  },

  // ── 2. Avenue de l'Indépendance — bouchon matinal ────────────────────────
  {
    name: 'Avenue de l\'Indépendance',
    waypoints: [
      [-18.9105, 47.5268],
      [-18.9090, 47.5263],
      [-18.9075, 47.5258],
      [-18.9065, 47.5255],
    ],
    speedMin: 2, speedMax: 15,
    points: 14,
    stopBefore: true,
  },

  // ── 3. Carrefour Antanimena — bottleneck légendaire de Tana ──────────────
  {
    name: 'Rond-point Antanimena (embouteillage)',
    waypoints: [
      [-18.9065, 47.5255],
      [-18.9055, 47.5252],
      [-18.9042, 47.5250],
      [-18.9028, 47.5252],
    ],
    speedMin: 1, speedMax: 8,
    points: 18,
    stopBefore: false,
  },

  // ── 4. Route des Hydrocarbures — ça se dégage légèrement ─────────────────
  {
    name: 'Route des Hydrocarbures',
    waypoints: [
      [-18.9028, 47.5252],
      [-18.9005, 47.5256],
      [-18.8985, 47.5260],
      [-18.8965, 47.5263],
    ],
    speedMin: 18, speedMax: 38,
    points: 12,
    stopBefore: true,
  },

  // ── 5. Ankorondrano entrée — feu + Jumbo Score ───────────────────────────
  {
    name: 'Ankorondrano (Jumbo / Score)',
    waypoints: [
      [-18.8965, 47.5263],
      [-18.8940, 47.5272],
      [-18.8915, 47.5280],
      [-18.8890, 47.5290],
    ],
    speedMin: 20, speedMax: 45,
    points: 12,
    stopBefore: true,
  },

  // ── 6. Zone Galaxy / Hotel Carlton — trafic fluide ───────────────────────
  {
    name: 'Zone Galaxy (Ankorondrano)',
    waypoints: [
      [-18.8890, 47.5290],
      [-18.8865, 47.5298],
      [-18.8845, 47.5305],
      [-18.8820, 47.5315],
    ],
    speedMin: 30, speedMax: 55,
    points: 10,
  },

  // ── 7. Boulevard de l'Europe — 2×2 voies, ça roule ──────────────────────
  {
    name: 'Boulevard de l\'Europe',
    waypoints: [
      [-18.8820, 47.5315],
      [-18.8795, 47.5330],
      [-18.8768, 47.5342],
      [-18.8740, 47.5352],
      [-18.8712, 47.5360],
    ],
    speedMin: 45, speedMax: 70,
    points: 12,
    stopBefore: true,
  },

  // ── 8. Ivandry — résidentiel, quelques dos d'âne ─────────────────────────
  {
    name: 'Ivandry (résidentiel)',
    waypoints: [
      [-18.8712, 47.5360],
      [-18.8685, 47.5368],
      [-18.8658, 47.5375],
      [-18.8630, 47.5378],
      [-18.8600, 47.5372],
    ],
    speedMin: 25, speedMax: 50,
    points: 14,
    stopBefore: false,
  },

  // ── 9. Sortie Ivandry vers RN1 — accélération progressive ────────────────
  {
    name: 'Sortie Ivandry → RN1',
    waypoints: [
      [-18.8600, 47.5372],
      [-18.8560, 47.5348],
      [-18.8520, 47.5318],
      [-18.8480, 47.5285],
      [-18.8445, 47.5252],
    ],
    speedMin: 50, speedMax: 80,
    points: 12,
  },

  // ── 10. RN1 — 2×2 voies, vitesse élevée ──────────────────────────────────
  {
    name: 'RN1 (route nationale, section rapide)',
    waypoints: [
      [-18.8445, 47.5252],
      [-18.8400, 47.5205],
      [-18.8352, 47.5158],
      [-18.8300, 47.5108],
      [-18.8248, 47.5058],
      [-18.8195, 47.5008],
    ],
    speedMin: 78, speedMax: 108,
    points: 18,
  },

  // ── 11. Approche Ambohidratrimo — ralentissement ──────────────────────────
  {
    name: 'Approche Ambohidratrimo',
    waypoints: [
      [-18.8195, 47.5008],
      [-18.8150, 47.4965],
      [-18.8105, 47.4922],
      [-18.8058, 47.4880],
      [-18.8010, 47.4840],
    ],
    speedMin: 45, speedMax: 72,
    points: 12,
    stopBefore: true,
  },

  // ── 12. Ambohidratrimo centre — arrivée ──────────────────────────────────
  {
    name: 'Ambohidratrimo (centre-ville)',
    waypoints: [
      [-18.8010, 47.4840],
      [-18.7978, 47.4812],
      [-18.7950, 47.4788],
      [-18.7925, 47.4768],
    ],
    speedMin: 8, speedMax: 28,
    points: 10,
    stopBefore: false,
  },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Interpolation linéaire entre a et b avec facteur t ∈ [0,1]. */
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

/** Bruit gaussien ≈ (Box-Muller simplifié) pour variation naturelle. */
const gauss = (mean: number, std: number) => {
  const u = 1 - Math.random();
  const v = Math.random();
  const z = Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  return mean + z * std;
};

/** Cap entre deux points (degrés). */
function bearing([lat1, lon1]: [number, number], [lat2, lon2]: [number, number]): number {
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const y = Math.sin(dLon) * Math.cos(φ2);
  const x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(dLon);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

/** Distance Haversine en mètres entre deux points. */
function haversine([lat1, lon1]: [number, number], [lat2, lon2]: [number, number]): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─── Génération du trajet complet ────────────────────────────────────────────

interface GpsPoint {
  lat: number;
  lon: number;
  speed: number;   // km/h
  course: number;  // degrés
  battery: number; // %
}

function buildTrip(): GpsPoint[] {
  const allPoints: GpsPoint[] = [];
  let battery = 87; // batterie de départ

  for (const seg of SEGMENTS) {
    const { waypoints, speedMin, speedMax, points: nPoints, stopBefore } = seg;
    const segPoints: [number, number][] = [];

    // Interpolation entre les waypoints du segment
    const segs = waypoints.length - 1;
    const pps = Math.floor(nPoints / segs);
    for (let s = 0; s < segs; s++) {
      for (let i = 0; i < pps; i++) {
        const t = i / pps;
        segPoints.push([
          lerp(waypoints[s][0], waypoints[s + 1][0], t),
          lerp(waypoints[s][1], waypoints[s + 1][1], t),
        ]);
      }
    }
    segPoints.push(waypoints[waypoints.length - 1]);

    const total = segPoints.length;

    for (let i = 0; i < total; i++) {
      const cur = segPoints[i];
      const next = segPoints[Math.min(i + 1, total - 1)];
      const course = bearing(cur, next);

      // ── Profil de vitesse ──────────────────────────────────────────────
      let t = i / Math.max(total - 1, 1); // progression dans le segment [0,1]

      // Arrêt complet sur les 3 derniers points si stopBefore
      let speed: number;
      if (stopBefore && i >= total - 3) {
        speed = Math.max(0, lerp(speedMin * 0.3, 0, (i - (total - 3)) / 2));
      } else if (stopBefore && i < 3) {
        // Redémarrage en douceur depuis l'arrêt précédent
        speed = lerp(0, speedMin, i / 3);
      } else {
        // Vitesse sinusoïdale dans la plage du segment + bruit gaussien
        const base = lerp(speedMin, speedMax, 0.5 + 0.5 * Math.sin(t * Math.PI));
        const noise = gauss(0, (speedMax - speedMin) * 0.08);
        speed = Math.max(0, Math.min(speedMax * 1.05, base + noise));
      }

      // Légère décroissance de batterie (~0.03% par point)
      battery = Math.max(45, battery - 0.03 - Math.random() * 0.02);

      allPoints.push({ lat: cur[0], lon: cur[1], speed, course, battery: Math.round(battery) });
    }
  }

  return allPoints;
}

// ─── Envoi OsmAnd → Traccar ──────────────────────────────────────────────────

function sendPosition(pt: GpsPoint, index: number, total: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const params = new URLSearchParams({
      id:        CONFIG.deviceId,
      lat:       pt.lat.toFixed(6),
      lon:       pt.lon.toFixed(6),
      timestamp: Math.floor(Date.now() / 1000).toString(),
      hdop:      '1.1',
      altitude:  CONFIG.altitude.toString(),
      speed:     (pt.speed / 1.852).toFixed(2), // km/h → knots (OsmAnd protocol)
      bearing:   pt.course.toFixed(0),
      batt:      pt.battery.toString(),
    });

    const req = http.request(
      {
        hostname: CONFIG.traccarHost,
        port:     CONFIG.traccarPort,
        path:     `/?${params}`,
        method:   'GET',
      },
      (res) => {
        const pct  = Math.round((index / total) * 100);
        const bar  = '█'.repeat(Math.floor(pct / 5)).padEnd(20, '░');
        const kmh  = pt.speed.toFixed(1).padStart(6);
        const batt = `${pt.battery}%`.padStart(4);
        const seg  = detectSegment(pt.lat);
        console.log(
          `[${String(index).padStart(3,'0')}/${total}] ${bar} ${pct}% | ` +
          `${kmh} km/h | 🔋${batt} | HTTP ${res.statusCode} | ${seg}`,
        );
        resolve();
      },
    );
    req.on('error', (err) => {
      console.warn(`  ⚠  Point ${index} ignoré (${err.message})`);
      resolve(); // on continue malgré l'erreur
    });
    req.end();
  });
}

/** Retourne le nom du segment courant selon la latitude. */
function detectSegment(lat: number): string {
  if (lat < -18.910) return 'Analakely';
  if (lat < -18.903) return 'Av. Indépendance';
  if (lat < -18.898) return 'Antanimena 🚦';
  if (lat < -18.890) return 'Route Hydrocarbures';
  if (lat < -18.882) return 'Ankorondrano';
  if (lat < -18.874) return 'Bd. de l\'Europe';
  if (lat < -18.858) return 'Ivandry';
  if (lat < -18.843) return 'Sortie Ivandry';
  if (lat < -18.820) return 'RN1 🏎️';
  if (lat < -18.800) return 'Approche Ambohidratrimo';
  return 'Ambohidratrimo';
}

// ─── Statistiques du trajet ──────────────────────────────────────────────────

function printStats(points: GpsPoint[]): void {
  let totalDist = 0;
  for (let i = 1; i < points.length; i++) {
    totalDist += haversine([points[i-1].lat, points[i-1].lon], [points[i].lat, points[i].lon]);
  }
  const speeds = points.map(p => p.speed);
  const avgSpeed = speeds.reduce((a, b) => a + b, 0) / speeds.length;
  const maxSpeed = Math.max(...speeds);
  const stopsCount = speeds.filter(s => s < 3).length;
  const durMin = Math.round((points.length * CONFIG.intervalMs) / 60000);

  console.log('\n┌─────────────────────────────────────────┐');
  console.log('│         STATISTIQUES DU TRAJET          │');
  console.log('├─────────────────────────────────────────┤');
  console.log(`│  Distance totale  : ${(totalDist / 1000).toFixed(2).padStart(7)} km           │`);
  console.log(`│  Points GPS       : ${String(points.length).padStart(7)}               │`);
  console.log(`│  Durée simulée    : ~${String(durMin).padStart(5)} min             │`);
  console.log(`│  Vitesse moyenne  : ${avgSpeed.toFixed(1).padStart(7)} km/h         │`);
  console.log(`│  Vitesse max      : ${maxSpeed.toFixed(1).padStart(7)} km/h         │`);
  console.log(`│  Points à l'arrêt : ${String(stopsCount).padStart(7)} (v < 3 km/h)  │`);
  console.log('└─────────────────────────────────────────┘\n');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  🗺️  iooeh GPS Simulator — Antananarivo');
  console.log(`  📡  Device   : ${CONFIG.deviceId}`);
  console.log(`  🎯  Trajet   : Analakely → Antanimena → Ankorondrano`);
  console.log(`                → Ivandry → RN1 → Ambohidratrimo`);
  console.log(`  ⏱️  Intervalle: ${CONFIG.intervalMs}ms par point`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const trip = buildTrip();
  printStats(trip);

  console.log('Envoi des positions GPS...\n');

  for (let i = 0; i < trip.length; i++) {
    await sendPosition(trip[i], i + 1, trip.length);
    if (i < trip.length - 1) {
      // Jitter ±15% de l'intervalle pour simuler l'irrégularité GPS réelle
      const jitter = (Math.random() - 0.5) * CONFIG.intervalMs * 0.3;
      await new Promise(r => setTimeout(r, CONFIG.intervalMs + jitter));
    }
  }

  console.log('\n✅  Simulation terminée. Véhicule arrivé à Ambohidratrimo.');
}

main().catch(err => {
  console.error('Erreur fatale :', err);
  process.exit(1);
});
