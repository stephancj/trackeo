/// Affichage des heures en heure locale de Madagascar.
///
/// Le backend stocke et renvoie tous les timestamps en **UTC** ('...Z'), et le
/// mobile les parse en UTC. Madagascar (Antananarivo) est à **UTC+3** toute
/// l'année (pas d'heure d'été), donc on applique un décalage fixe — robuste même
/// si le fuseau de l'appareil/navigateur est mal réglé (sinon les heures
/// s'affichaient en UTC).
library;

const Duration kAntananarivoOffset = Duration(hours: 3);

/// Convertit un instant en heure locale de Madagascar.
DateTime toMgTime(DateTime dt) => dt.toUtc().add(kAntananarivoOffset);

/// "14:23" en heure de Madagascar.
String fmtMgHm(DateTime dt) {
  final t = toMgTime(dt);
  return '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
