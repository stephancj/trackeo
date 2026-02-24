import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/geofences_provider.dart';

class CreateGeofenceView extends ConsumerStatefulWidget {
  const CreateGeofenceView({super.key});

  @override
  ConsumerState<CreateGeofenceView> createState() => _CreateGeofenceViewState();
}

class _CreateGeofenceViewState extends ConsumerState<CreateGeofenceView> {
  final MapController _mapController = MapController();
  double _radius = 500;
  bool _onEntry = true;
  bool _onExit = false;
  LatLng _center = const LatLng(48.8566, 2.3522); // Default to Paris
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController(
    text: 'Home',
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  setState(() {
                    _center = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackeo.mobile',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                    radius: _radius,
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              // Center Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top action bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'New Geofence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map controls
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45 + 16,
            child: Column(
              children: [
                _buildMapControlButton(Icons.my_location),
                const SizedBox(height: 8),
                _buildMapControlButton(Icons.layers),
              ],
            ),
          ),

          // Bottom Sheet / Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.48,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Radius Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Zone Radius',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_radius.toInt()}m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radius,
                      min: 100,
                      max: 2000,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.divider,
                      onChanged: (val) {
                        setState(() {
                          _radius = val;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '100m',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '2km',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Zone Name
                    const Text(
                      'Zone Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: AppColors.textHint,
                        ),
                        hintText: 'Enter name',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alert Triggers
                    const Text(
                      'Alert Triggers',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTriggerCard(
                            'On Entry',
                            Icons.login,
                            _onEntry,
                            (v) => setState(() => _onEntry = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTriggerCard(
                            'On Exit',
                            Icons.logout,
                            _onExit,
                            (v) => setState(() => _onExit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Save Zone'),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_nameController.text.trim().isEmpty) return;

                                setState(() => _isSaving = true);
                                final payload = {
                                  'name': _nameController.text.trim(),
                                  'centerLat': _center.latitude,
                                  'centerLon': _center.longitude,
                                  'radiusM': _radius,
                                  'isActive': true,
                                  // Add alert triggers here later based on backend schema
                                };

                                final result = await ref
                                    .read(geofencesProvider.notifier)
                                    .createGeofence(payload);

                                if (!mounted) return;

                                setState(() => _isSaving = false);
                                if (result != null) {
                                  if (context.mounted) Navigator.pop(context);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to save geofence',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCard(
    String title,
    IconData icon,
    bool isActive,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.textHint,
                ),
                Switch.adaptive(
                  value: isActive,
                  activeColor: AppColors.primary,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary),
        onPressed: () {},
      ),
    );
  }
}
