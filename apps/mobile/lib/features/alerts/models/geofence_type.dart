import 'package:flutter/material.dart';

/// Catégorie de zone → icône, couleur et libellé. La clé (`key`) est ce qui est
/// persité en base (colonne `geofences.type`).
class GeofenceTypeInfo {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const GeofenceTypeInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Catalogue des types de zone proposés à l'utilisateur.
const List<GeofenceTypeInfo> kGeofenceTypes = [
  GeofenceTypeInfo(
    key: 'home',
    label: 'Domicile',
    icon: Icons.home_rounded,
    color: Color(0xFF5B8DEF),
  ),
  GeofenceTypeInfo(
    key: 'work',
    label: 'Bureau',
    icon: Icons.work_rounded,
    color: Color(0xFF9333EA),
  ),
  GeofenceTypeInfo(
    key: 'school',
    label: 'École',
    icon: Icons.school_rounded,
    color: Color(0xFFF97316),
  ),
  GeofenceTypeInfo(
    key: 'family',
    label: 'Famille',
    icon: Icons.favorite_rounded,
    color: Color(0xFFEC4899),
  ),
  GeofenceTypeInfo(
    key: 'shop',
    label: 'Commerce',
    icon: Icons.storefront_rounded,
    color: Color(0xFF14B8A6),
  ),
  GeofenceTypeInfo(
    key: 'custom',
    label: 'Autre',
    icon: Icons.place_rounded,
    color: Color(0xFF4ECB8D),
  ),
];

/// Résout la catégorie d'une zone, avec repli sur "Autre" si la clé est inconnue.
GeofenceTypeInfo geofenceTypeInfo(String key) {
  return kGeofenceTypes.firstWhere(
    (t) => t.key == key,
    orElse: () => kGeofenceTypes.last,
  );
}
