/**
 * simulate.ts — Simulateur de mouvement GPS pour Trackeo
 *
 * Envoie des requêtes HTTP GET au protocole OsmAnd de Traccar (port 5055)
 * pour simuler le déplacement d'un véhicule sur une route.
 *
 * Usage :
 *   npx ts-node scripts/simulate.ts
 *   npx ts-node scripts/simulate.ts --id=device001 --points=50 --interval=2000
 */

import http from 'http';

// ─── Configuration ────────────────────────────────────────────────────────────
const CONFIG = {
  traccarHost: process.env.TRACCAR_HOST ?? 'localhost',
  traccarPort: parseInt(process.env.TRACCAR_PORT ?? '5055', 10),
  deviceId: process.env.DEVICE_ID ?? 'trackeo-sim-001',
  intervalMs: parseInt(process.env.INTERVAL_MS ?? '3000', 10),
  totalPoints: parseInt(process.env.TOTAL_POINTS ?? '30', 10),
};

// ─── Route simulée (Paris → La Défense) ──────────────────────────────────────
const ROUTE_WAYPOINTS: [number, number][] = [
  [48.8566, 2.3522],   // Paris Centre
  [48.8600, 2.3400],
  [48.8650, 2.3100],
  [48.8700, 2.2900],
  [48.8730, 2.2700],
  [48.8760, 2.2500],
  [48.8790, 2.2300],
  [48.8920, 2.2420],   // La Défense
];

// ─── Interpolation linéaire entre waypoints ───────────────────────────────────
function interpolateRoute(
  waypoints: [number, number][],
  totalPoints: number,
): [number, number][] {
  const result: [number, number][] = [];
  const segments = waypoints.length - 1;
  const pointsPerSegment = Math.floor(totalPoints / segments);

  for (let s = 0; s < segments; s++) {
    const [lat1, lon1] = waypoints[s];
    const [lat2, lon2] = waypoints[s + 1];
    for (let i = 0; i < pointsPerSegment; i++) {
      const t = i / pointsPerSegment;
      result.push([
        lat1 + (lat2 - lat1) * t,
        lon1 + (lon2 - lon1) * t,
      ]);
    }
  }
  result.push(waypoints[waypoints.length - 1]);
  return result;
}

// ─── Envoi d'une position via le protocole OsmAnd ─────────────────────────────
function sendPosition(
  deviceId: string,
  lat: number,
  lon: number,
  speed: number,
  bearing: number,
  index: number,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const timestamp = Math.floor(Date.now() / 1000);
    const params = new URLSearchParams({
      id: deviceId,
      lat: lat.toFixed(6),
      lon: lon.toFixed(6),
      timestamp: timestamp.toString(),
      hdop: '1.0',
      altitude: '35',
      speed: speed.toFixed(1),
      bearing: bearing.toFixed(1),
    });

    const options: http.RequestOptions = {
      hostname: CONFIG.traccarHost,
      port: CONFIG.traccarPort,
      path: `/?${params.toString()}`,
      method: 'GET',
    };

    const req = http.request(options, (res) => {
      console.log(
        `[${index.toString().padStart(3, '0')}] ✓ HTTP ${res.statusCode} | ` +
        `lat=${lat.toFixed(5)}, lon=${lon.toFixed(5)}, ` +
        `speed=${speed.toFixed(1)} km/h, bearing=${bearing.toFixed(0)}°`,
      );
      resolve();
    });

    req.on('error', (err) => {
      console.error(`[${index}] ✗ Erreur : ${err.message}`);
      reject(err);
    });

    req.end();
  });
}

// ─── Calcul du cap (bearing) entre deux points ────────────────────────────────
function calculateBearing(
  [lat1, lon1]: [number, number],
  [lat2, lon2]: [number, number],
): number {
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const lat1Rad = (lat1 * Math.PI) / 180;
  const lat2Rad = (lat2 * Math.PI) / 180;
  const y = Math.sin(dLon) * Math.cos(lat2Rad);
  const x =
    Math.cos(lat1Rad) * Math.sin(lat2Rad) -
    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main(): Promise<void> {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  Trackeo GPS Simulator');
  console.log(`  Device  : ${CONFIG.deviceId}`);
  console.log(`  Target  : ${CONFIG.traccarHost}:${CONFIG.traccarPort}`);
  console.log(`  Points  : ${CONFIG.totalPoints}`);
  console.log(`  Interval: ${CONFIG.intervalMs}ms`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const route = interpolateRoute(ROUTE_WAYPOINTS, CONFIG.totalPoints);

  for (let i = 0; i < route.length; i++) {
    const current = route[i];
    const next = route[Math.min(i + 1, route.length - 1)];
    const bearing = calculateBearing(current, next);
    // Vitesse simulée entre 30 et 70 km/h avec légère variation
    const speed = 40 + Math.random() * 30;

    try {
      await sendPosition(
        CONFIG.deviceId,
        current[0],
        current[1],
        speed,
        bearing,
        i + 1,
      );
    } catch {
      console.warn(`Position ${i + 1} ignorée, Traccar inaccessible.`);
    }

    if (i < route.length - 1) {
      await new Promise((r) => setTimeout(r, CONFIG.intervalMs));
    }
  }

  console.log('\n✅ Simulation terminée.');
}

main().catch((err) => {
  console.error('Erreur fatale :', err);
  process.exit(1);
});
