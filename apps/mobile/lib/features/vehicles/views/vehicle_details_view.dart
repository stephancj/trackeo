import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicles_provider.dart';
import '../../../core/providers/geocoding_provider.dart';
import '../../../core/navigation/app_shell.dart';
import 'widgets/status_badge.dart';

class VehicleDetailsView extends ConsumerWidget {
  final Vehicle vehicle;
  const VehicleDetailsView({super.key, required this.vehicle});

  static const double _heroHeight = 280.0;

  IconData _vehicleIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('bus') || n.contains('school')) return Icons.directions_bus;
    if (n.contains('truck') || n.contains('transit') || n.contains('van')) {
      return Icons.local_shipping;
    }
    if (n.contains('moto') || n.contains('pcx') || n.contains('bike')) {
      return Icons.pedal_bike;
    }
    return Icons.directions_car;
  }

  Color _heroAccent(String name) {
    final n = name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFF3B82F6);
    if (n.contains('transit')) return const Color(0xFFE65100);
    if (n.contains('bus')) return const Color(0xFF9C27B0);
    if (n.contains('tesla')) return const Color(0xFFEF4444);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(selectedVehicleProvider) ?? this.vehicle;
    final pos = vehicle.position;
    final addressAsync = pos != null
        ? ref.watch(reverseGeocodeProvider(LatLng(pos.lat, pos.lon)))
        : null;
    final accent = _heroAccent(vehicle.name);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: _heroHeight,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                tooltip: 'Modifier',
                onPressed: () => _showEditSheet(context, ref, vehicle),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroBackground(
                vehicle: vehicle,
                icon: _vehicleIcon(vehicle.name),
                accent: accent,
                topPad: topPad,
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Horizontal Stats Strip ─────────────────────────────────
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _StatPill(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'Batterie',
                        value: pos?.battery != null ? '${pos!.battery}%' : '--',
                        color: (pos?.battery ?? 100) > 20
                            ? AppColors.primary
                            : AppColors.statusAlert,
                        progress: (pos?.battery ?? 0) / 100,
                      ),
                      _StatPill(
                        icon: Icons.speed_rounded,
                        label: 'Vitesse',
                        value: pos?.speedKmh != null
                            ? '${pos!.speedKmh.toStringAsFixed(0)} km/h'
                            : '0 km/h',
                        color: (pos?.speedKmh ?? 0) > 120
                            ? AppColors.statusAlert
                            : AppColors.statusIdle,
                        progress: ((pos?.speedKmh ?? 0) / 140).clamp(0.0, 1.0),
                      ),
                      _StatPill(
                        icon: Icons.power_settings_new_rounded,
                        label: 'Moteur',
                        value: pos?.ignition == true ? 'Allumé' : 'Éteint',
                        color: pos?.ignition == true
                            ? AppColors.primary
                            : AppColors.textHint,
                        progress: pos?.ignition == true ? 1.0 : 0.0,
                      ),
                      _StatPill(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: 'Signal',
                        value: (pos?.rssi ?? 25) > 20 ? 'Fort' : 'Faible',
                        color: AppColors.primary,
                        progress: (pos?.rssi ?? 25) / 31,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Status Row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      StatusBadge(status: vehicle.status),
                      const SizedBox(width: 10),
                      Text(
                        vehicle.lastUpdate != null
                            ? 'Mis à jour ${timeago.format(vehicle.lastUpdate!, locale: 'fr')}'
                            : 'Jamais mis à jour',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Map Preview ───────────────────────────────────────────
                if (pos != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MapCard(
                      vehicle: vehicle,
                      pos: pos,
                      addressAsync: addressAsync,
                      ref: ref,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Premium Lock Row ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FeatureCard(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.textHint,
                    iconBg: AppColors.divider.withValues(alpha: 0.3),
                    title: 'Verrouillage à distance',
                    subtitle: 'Disponible avec un plan Premium',
                    trailing: Tooltip(
                      message: 'Disponible avec un plan Premium',
                      child: Switch.adaptive(
                        value: false,
                        onChanged: null,
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Emergency Button ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EmergencyButton(
                    onTap: () => HapticFeedback.heavyImpact(),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final nameController = TextEditingController(text: vehicle.name);
    final plateController = TextEditingController(text: vehicle.plate ?? '');
    final serialController = TextEditingController(text: vehicle.serialNumber);
    final imageController = TextEditingController(text: vehicle.imageUrl ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditVehicleSheet(
        nameController: nameController,
        plateController: plateController,
        serialController: serialController,
        imageController: imageController,
        onSave: () async {
          Navigator.pop(ctx);
          try {
            await ref.read(vehiclesProvider.notifier).updateVehicle(
              vehicle.id,
              {
                'name': nameController.text,
                'uniqueId': serialController.text,
                'attributes': {
                  'plate': plateController.text,
                  'imageUrl': imageController.text,
                },
              },
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Véhicule mis à jour'),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur : $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ── Hero Background ────────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  final Vehicle vehicle;
  final IconData icon;
  final Color accent;
  final double topPad;

  const _HeroBackground({
    required this.vehicle,
    required this.icon,
    required this.accent,
    required this.topPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            Color.lerp(AppColors.primaryDark, accent, 0.35)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Vehicle image or icon
          Positioned(
            top: topPad + 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: vehicle.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          vehicle.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            icon,
                            size: 52,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 52,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
              ),
            ),
          ),

          // Name + plate at bottom
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  vehicle.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (vehicle.plate != null && vehicle.plate!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          vehicle.plate!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vehicle.serialNumber,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Card ──────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final Vehicle vehicle;
  final VehiclePosition pos;
  final AsyncValue<String?>? addressAsync;
  final WidgetRef ref;

  const _MapCard({
    required this.vehicle,
    required this.pos,
    required this.addressAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref.read(activeTabProvider.notifier).state = 1;
              ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
              Navigator.pop(context);
            },
            child: AbsorbPointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(pos.lat, pos.lon),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppMapTiles.positron,
                    subdomains: AppMapTiles.subdomains,
                    retinaMode: true,
                    userAgentPackageName: 'mg.trackeo.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(pos.lat, pos.lon),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom address overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: addressAsync?.when(
                          data: (addr) => Text(
                            addr ?? 'Position inconnue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text(
                            'Localisation...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          error: (_, __) => const Text(
                            'Position inconnue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ) ??
                        const SizedBox.shrink(),
                  ),
                  const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── Emergency Button ──────────────────────────────────────────────────────────

class _EmergencyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EmergencyButton({required this.onTap});

  @override
  State<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<_EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.statusAlert,
                AppColors.statusAlert.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.statusAlert.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Coupure d\'urgence',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Vehicle Bottom Sheet ─────────────────────────────────────────────────

class _EditVehicleSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController plateController;
  final TextEditingController serialController;
  final TextEditingController imageController;
  final VoidCallback onSave;

  const _EditVehicleSheet({
    required this.nameController,
    required this.plateController,
    required this.serialController,
    required this.imageController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            const Text(
              'Modifier le véhicule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),

            _SheetField(
              controller: nameController,
              label: 'Nom du véhicule',
              hint: 'ex. Toyota RAV4',
              icon: Icons.directions_car_rounded,
            ),
            const SizedBox(height: 14),
            _SheetField(
              controller: plateController,
              label: 'Plaque d\'immatriculation',
              hint: 'ex. ABC-1234',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 14),
            _SheetField(
              controller: serialController,
              label: 'Numéro de série / IMEI',
              hint: '',
              icon: Icons.fingerprint_rounded,
            ),
            const SizedBox(height: 14),
            _SheetField(
              controller: imageController,
              label: 'URL de la photo',
              hint: 'https://...',
              icon: Icons.image_outlined,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
