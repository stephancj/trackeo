import { Injectable, NotFoundException } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { DeviceAssignment } from '../admin/device-assignment.entity';
import { PositionsService } from '../positions/positions.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { Trip } from './trip.entity';

@Injectable()
export class TripsService {
  constructor(
    @InjectRepository(Trip) private readonly tripRepo: Repository<Trip>,
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
    private readonly positions: PositionsService,
    private readonly vehicles: VehiclesService,
  ) {}

  async syncDevice(deviceId: number, from: Date, to: Date) {
    const [segments, assignment] = await Promise.all([
      this.positions.getTripLog(deviceId, from, to),
      this.assignmentRepo.findOne({ where: { deviceId } }),
    ]);
    for (const segment of segments) {
      const points = await this.positions.getHistory(
        deviceId,
        segment.startTime,
        segment.endTime,
        5000,
      );
      await this.tripRepo.upsert(
        {
          deviceId,
          ownerId: assignment?.userId ?? null,
          startTime: segment.startTime,
          endTime: segment.endTime,
          distanceKm: segment.distanceKm,
          durationSec: segment.durationMin * 60,
          maxSpeedKmh: segment.maxSpeedKmh,
          startLat: segment.startLat,
          startLon: segment.startLon,
          endLat: segment.endLat,
          endLon: segment.endLon,
          pointCount: segment.pointCount,
          path: points.map((p) => ({
            lat: p.lat,
            lon: p.lon,
            at: p.deviceTime.toISOString(),
            speedKmh: p.speedKmh,
          })),
        },
        ['deviceId', 'startTime'],
      );
    }
    return segments.length;
  }
  async listForUser(userId: number, deviceId: number, from: Date, to: Date) {
    await this.vehicles.assertOwner(deviceId, userId);
    await this.syncDevice(deviceId, from, to);
    return this.tripRepo.find({
      where: { deviceId, startTime: Between(from, to) },
      order: { startTime: 'DESC' },
    });
  }
  async playback(userId: number, id: string) {
    const trip = await this.tripRepo.findOne({ where: { id } });
    if (!trip) throw new NotFoundException('Trajet introuvable.');
    await this.vehicles.assertOwner(trip.deviceId, userId);
    return trip;
  }
  async listAdmin(deviceId: number, from: Date, to: Date) {
    await this.syncDevice(deviceId, from, to);
    return this.tripRepo.find({
      where: { deviceId, startTime: Between(from, to) },
      order: { startTime: 'DESC' },
    });
  }

  csv(trips: Trip[]) {
    const header =
      'debut,fin,distance_km,duree_minutes,vitesse_max_kmh,points\n';
    return Buffer.from(
      header +
        trips
          .map((t) =>
            [
              t.startTime.toISOString(),
              t.endTime.toISOString(),
              t.distanceKm,
              Math.round(t.durationSec / 60),
              t.maxSpeedKmh,
              t.pointCount,
            ].join(','),
          )
          .join('\n'),
      'utf8',
    );
  }
  pdf(trips: Trip[], title: string) {
    const lines = [
      title,
      `Généré le ${new Date().toLocaleString('fr-FR')}`,
      '',
      ...trips.flatMap((t, i) => [
        `Trajet ${i + 1} — ${t.startTime.toLocaleString('fr-FR')}`,
        `${t.distanceKm.toFixed(1)} km · ${Math.round(t.durationSec / 60)} min · max ${t.maxSpeedKmh.toFixed(0)} km/h`,
        '',
      ]),
    ];
    return this.simplePdf(lines);
  }
  private simplePdf(lines: string[]) {
    const esc = (s: string) =>
      s
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^\x20-\x7E]/g, '-')
        .replace(/[()\\]/g, '\\$&');
    const content = `BT /F1 12 Tf 50 790 Td 16 TL ${lines
      .slice(0, 42)
      .map((line, i) => `${i ? 'T* ' : ''}(${esc(line)}) Tj`)
      .join(' ')} ET`;
    const objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
      `<< /Length ${Buffer.byteLength(content)} >>\nstream\n${content}\nendstream`,
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];
    let pdf = '%PDF-1.4\n';
    const offsets = [0];
    objects.forEach((obj, i) => {
      offsets.push(Buffer.byteLength(pdf));
      pdf += `${i + 1} 0 obj\n${obj}\nendobj\n`;
    });
    const xref = Buffer.byteLength(pdf);
    pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n${offsets
      .slice(1)
      .map((o) => String(o).padStart(10, '0') + ' 00000 n ')
      .join(
        '\n',
      )}\ntrailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
    return Buffer.from(pdf, 'binary');
  }
  @Cron('0 */15 * * * *') async aggregateRecent() {
    const assignments = await this.assignmentRepo.find();
    const to = new Date();
    const from = new Date(to.getTime() - 48 * 3600_000);
    for (const a of assignments)
      await this.syncDevice(a.deviceId, from, to).catch(() => undefined);
  }
}
