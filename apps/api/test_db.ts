import "reflect-metadata";
import { DataSource } from "typeorm";
import { Device } from "./src/devices/device.entity";
import { Position } from "./src/positions/position.entity";

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
        console.log("new Date getTime (ms):", lastUpdate ? new Date(lastUpdate).getTime() : "null");
        console.log("Date.now() (ms):", Date.now());
        if (lastUpdate) {
            const secondsAgo = (Date.now() - new Date(lastUpdate).getTime()) / 1000;
            console.log("secondsAgo:", secondsAgo);
        }
    }
    await dataSource.destroy();
}
run();
