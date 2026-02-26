import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Un provider mis en cache localement via keepAlive() pour éviter de
/// flooder Nominatim à chaque reconstruction ou navigation.
class NominatimCache {
  static final Map<String, String> _cache = {};

  static Future<String?> reverseGeocode(double lat, double lon) async {
    // Arrondi à 4 décimales (~11 mètres de précision) pour augmenter le hit cache
    final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent': 'Trackeo Mobile App / contact@projettrackeo.mg',
          },
        ),
      );

      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lon,
          'zoom': 18, // street level
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final address = response.data['address'];
        final road =
            address['road'] ??
            address['pedestrian'] ??
            address['neighbourhood'] ??
            address['suburb'];
        final city =
            address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'];

        String? result;
        if (road != null && city != null) {
          result = '$road, $city';
        } else if (road != null) {
          result = road;
        } else if (city != null) {
          result = city;
        } else {
          result = response.data['name'] ?? response.data['display_name'];
        }

        if (result != null) {
          _cache[key] = result;
          return result;
        }
      }
    } catch (e) {
      // Ignorer silencieusement pour éviter le spam de log, et on renvoie null
    }
    return null;
  }
}

final reverseGeocodeProvider = FutureProvider.family.autoDispose<String?, LatLng>((
  ref,
  latLng,
) async {
  // Optionnel: on peut garder en cache Riverpod pour la session courante en plus du cache Map static.
  ref.keepAlive();
  return NominatimCache.reverseGeocode(latLng.latitude, latLng.longitude);
});
