export type VehicleStatus = 'online' | 'idle' | 'offline';

export interface VehicleSleepModeDto {
  active: boolean;
  triggered: boolean;
  armedAt: Date;
  triggeredAt: Date | null;
  movementThresholdM: number;
  lastDistanceM: number;
}

export interface VehiclePositionDto {
  lat: number;
  lon: number;
  speedKmh: number;
  course: number;
  address: string | null;
  /** Niveau de batterie en % extrait des attributs Traccar (peut être null) */
  battery: number | null;
  /** true = branché sur alimentation externe (voiture / chargeur) */
  charging: boolean | null;
  /** Engine status (ignition) */
  ignition: boolean | null;
  /** Signal strength / RSSI */
  rssi: number | null;
  deviceTime: Date;
}

export interface VehicleDto {
  id: number;
  /** Nom du véhicule (ex: "Toyota RAV4") */
  name: string;
  /** Numéro de série / IMEI */
  serialNumber: string;
  /** Plaque d'immatriculation (nullable) */
  plate: string | null;
  /** Image URL for the vehicle mockup */
  imageUrl: string | null;
  /** online = en mouvement, idle = connecté mais arrêté, offline = déconnecté */
  status: VehicleStatus;
  lastUpdate: Date | null;
  position: VehiclePositionDto | null;
  /** Veille antivol armée depuis la position d'arrêt, null si désactivée. */
  sleepMode: VehicleSleepModeDto | null;
}
