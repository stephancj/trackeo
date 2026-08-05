/**
 * test-speed-alert.ts — Envoie 5 positions à 135 km/h pour tester l'alerte vitesse.
 *
 * Usage:
 *   npx ts-node scripts/test-speed-alert.ts
 *
 * Variables d'environnement optionnelles:
 *   TRACCAR_HOST  (défaut: traccar.iooeh.com)
 *   TRACCAR_PORT  (défaut: 15055)
 *   DEVICE_ID     (défaut: trackeo-sim-001)
 *   SPEED_KMH     (défaut: 135)
 */

import * as http from 'http';

const HOST      = process.env.TRACCAR_HOST ?? 'localhost';
const PORT      = parseInt(process.env.TRACCAR_PORT ?? '5055', 10);
const DEVICE_ID = process.env.DEVICE_ID    ?? 'tana-sim-001';
const SPEED_KMH = parseFloat(process.env.SPEED_KMH ?? '135');
const POINTS    = 5;

// Position fixe : RN1 Antananarivo
const LAT = -18.835;
const LON =  47.512;

function send(i: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const params = new URLSearchParams({
      id:        DEVICE_ID,
      lat:       LAT.toFixed(6),
      lon:       LON.toFixed(6),
      timestamp: Math.floor(Date.now() / 1000).toString(),
      hdop:      '1.0',
      altitude:  '1280',
      speed:     (SPEED_KMH / 1.852).toFixed(2), // km/h → knots
      bearing:   '340',
      batt:      '75',
    });

    const req = http.request(
      { hostname: HOST, port: PORT, path: `/?${params}`, method: 'GET' },
      (res) => {
        console.log(`  [${i}/${POINTS}] ${SPEED_KMH} km/h → HTTP ${res.statusCode}`);
        resolve();
      },
    );
    req.on('error', reject);
    req.end();
  });
}

async function main() {
  console.log(`\n🚨 Test alerte vitesse — ${SPEED_KMH} km/h`);
  console.log(`   Device : ${DEVICE_ID}`);
  console.log(`   Traccar: ${HOST}:${PORT}\n`);

  for (let i = 1; i <= POINTS; i++) {
    await send(i);
    await new Promise(r => setTimeout(r, 1000));
  }

  console.log('\n✅ Positions envoyées.');
  console.log('⏳ Attendre ~30s que le cron checkVehicleAlerts se déclenche.');
  console.log('📱 Vérifier l\'onglet Alertes dans l\'app.\n');
}

main().catch(console.error);
