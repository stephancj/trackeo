import "reflect-metadata";
import { DataSource } from "typeorm";
import { Device } from "./apps/api/src/devices/device.entity";
import { Position } from "./apps/api/src/positions/position.entity";

const dataSource = new DataSource({
  type: "postgres",
  host: "localhost",
  port: 5432,
  username: "trackeo",
  password: "Password_1234",
  database: "traccar_db",
  entities: [Device, Position],
  extra: { options: "-c timezone=UTC" },
});

async function run() {
  await dataSource.initialize();
  const devices = await dataSource.getRepository(Device).find();
  console.log("Devices from DB:", devices);
  for (const device of devices) {
    const lastUpdate = device.lastUpdate;
    console.log("lastUpdate:", lastUpdate);
    console.log("new Date getTime (ms):", new Date(lastUpdate).getTime());
    console.log("Date.now() (ms):", Date.now());
    const secondsAgo = (Date.now() - new Date(lastUpdate).getTime()) / 1000;
    console.log("secondsAgo:", secondsAgo);
    
    // Simulate computeStatus
    const speedKmh = 0;
    const traccarStatus = device.status;
    let computedStatus = 'offline';
    if (!lastUpdate) computedStatus = 'offline';
    else if (secondsAgo > 600) computedStatus = 'offline';
    else if (traccarStatus === 'offline') computedStatus = 'offline';
    else computedStatus = speedKmh > 1 ? 'online' : 'idle';
    console.log("computedStatus:", computedStatus);
  }
  await dataSource.destroy();
}
run();
