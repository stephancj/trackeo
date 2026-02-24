export type VehicleStatus = 'online' | 'idle' | 'offline';

export interface VehiclePositionDto {
  lat: number;
  lon: number;
  speedKmh: number;
  course: number;
  address: string | null;
  /** Niveau de batterie en % extrait des attributs Traccar (peut être null) */
  battery: number | null;
  deviceTime: Date;
}

export interface VehicleDto {
  id: number;
  /** Nom du véhicule (ex: "Toyota RAV4") */
  name: string;
  /** Identifiant unique — immatriculation ou IMEI */
  plate: string;
  /** online = en mouvement, idle = connecté mais arrêté, offline = déconnecté */
  status: VehicleStatus;
  lastUpdate: Date | null;
  position: VehiclePositionDto | null;
}
