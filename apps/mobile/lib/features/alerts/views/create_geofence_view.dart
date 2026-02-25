import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../providers/geofences_provider.dart';

class CreateGeofenceView extends ConsumerStatefulWidget {
  const CreateGeofenceView({super.key});

  @override
  ConsumerState<CreateGeofenceView> createState() => _CreateGeofenceViewState();
}

class _CreateGeofenceViewState extends ConsumerState<CreateGeofenceView>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _radius = 500;
  bool _onEntry = true;
  bool _onExit = false;
  // Default to Antananarivo (project's target city)
  LatLng _center = const LatLng(-18.8792, 47.5079);
  bool _isSaving = false;
  bool _isDragging = false;
  final TextEditingController _nameController = TextEditingController(
    text: 'Home',
  );

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _centerOnMarker() {
    _mapController.move(_center, _mapController.camera.zoom);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    HapticFeedback.selectionClick();
    setState(() {
      _center = point;
    });
    _ensureCircleVisible();
  }

  void _ensureCircleVisible() {
    // If the circle's bounding box is not fully visible, fit it
    // This provides the "adapter avec le zoom" functionality
    final distance = const Distance();
    final north = distance.offset(_center, _radius, 0);
    final south = distance.offset(_center, _radius, 180);
    final east = distance.offset(_center, _radius, 90);
    final west = distance.offset(_center, _radius, 270);

    final bounds = LatLngBounds.fromPoints([north, south, east, west]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(100), // Nice margin to see context
      ),
    );
  }

  Future<void> _saveGeofence() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a zone name'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'name': name,
      'centerLat': _center.latitude,
      'centerLon': _center.longitude,
      'radiusM': _radius.toInt(), // API expects integer
      'isActive': true,
    };

    final result = await ref
        .read(geofencesProvider.notifier)
        .createGeofence(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result != null) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save geofence. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPanelHeight = MediaQuery.of(context).size.height * 0.46;

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackeo.mobile',
              ),
              // Geofence circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2.5,
                    radius: _radius,
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              // Draggable center marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 56,
                    height: 56,
                    child: GestureDetector(
                      onPanStart: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _isDragging = true);
                      },
                      onPanUpdate: (details) {
                        // Convert drag delta (pixels) to lat/lng offset
                        final camera = _mapController.camera;
                        final zoom = camera.zoom;
                        // Meters per pixel at current zoom and latitude
                        final metersPerPixel =
                            156543.03392 *
                            math.cos(_center.latitude * math.pi / 180) /
                            math.pow(2, zoom);
                        final latPerPixel = metersPerPixel / 111320;
                        final lonPerPixel =
                            metersPerPixel /
                            (111320 *
                                math.cos(_center.latitude * math.pi / 180));

                        setState(() {
                          _center = LatLng(
                            _center.latitude - details.delta.dy * latPerPixel,
                            _center.longitude + details.delta.dx * lonPerPixel,
                          );
                        });
                      },
                      onPanEnd: (_) {
                        HapticFeedback.lightImpact();
                        setState(() => _isDragging = false);
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isDragging ? 1.2 : _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(
                                  alpha: _isDragging ? 0.25 : 0.15,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: _isDragging ? 0.8 : 0.4,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Pin icon
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 36,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── DRAG HINT ───────────────────────────────────────────────────
          if (!_isDragging)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_with_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Drag pin or tap map to position',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── TOP BAR ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'New Geofence',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  _buildCircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // ── MAP CONTROLS (right side) ────────────────────────────────────
          Positioned(
            right: 16,
            bottom: bottomPanelHeight + 20,
            child: Column(
              children: [
                // Center/locate button — moves camera back to the pin
                _buildMapFabButton(
                  icon: Icons.my_location_rounded,
                  onTap: _centerOnMarker,
                  tooltip: 'Center on pin',
                  isPrimary: true,
                ),
                const SizedBox(height: 8),
                // Zoom in
                _buildMapFabButton(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                // Zoom out
                _buildMapFabButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
              ],
            ),
          ),

          // ── COORDS CHIP ──────────────────────────────────────────────────
          Positioned(
            left: 16,
            bottom: bottomPanelHeight + 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_center.latitude.toStringAsFixed(5)}°',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_center.longitude.toStringAsFixed(5)}°',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOTTOM PANEL ─────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: bottomPanelHeight,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Zone Name ──────────────────────────────────────────
                    _buildLabel('Zone Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.label_outline_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        hintText: 'e.g. Home, Office…',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Radius Slider ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Zone Radius'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _radius >= 1000
                                ? '${(_radius / 1000).toStringAsFixed(1)} km'
                                : '${_radius.toInt()} m',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 22,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: _radius.clamp(100, _getMaxRadiusForZoom()),
                        min: 100,
                        max: _getMaxRadiusForZoom(),
                        onChanged: (val) {
                          setState(() => _radius = val);
                        },
                        onChangeEnd: (val) {
                          _ensureCircleVisible();
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '100 m',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '5 km',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Alert Triggers ─────────────────────────────────────
                    _buildLabel('Alert Triggers'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTriggerCard(
                            'On Entry',
                            Icons.login_rounded,
                            _onEntry,
                            (v) => setState(() => _onEntry = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTriggerCard(
                            'On Exit',
                            Icons.logout_rounded,
                            _onExit,
                            (v) => setState(() => _onExit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Save Button ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGeofence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Zone',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMapFabButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : AppColors.textPrimary,
            size: 20,
          ),
        ),
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
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!isActive);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.divider.withValues(alpha: 0.5),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.divider.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textHint,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxRadiusForZoom() {
    try {
      final camera = _mapController.camera;
      final zoom = camera.zoom;
      // meters_per_pixel = 156543 * cos(lat) / 2^zoom
      final metersPerPixel =
          156543.0 *
          math.cos(_center.latitude * math.pi / 180) /
          math.pow(2, zoom);
      // We want the max value to allow filling the screen (e.g. 400 pixels radius)
      return (metersPerPixel * 400).clamp(500.0, 10000.0);
    } catch (_) {
      return 5000.0;
    }
  }
}
