import 'package:flutter/material.dart';
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

  Color _iconBgColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFFE8F0FE);
    if (n.contains('transit')) return const Color(0xFFFDF1E6);
    if (n.contains('bus')) return const Color(0xFFF3E8FD);
    if (n.contains('tesla')) return const Color(0xFFFDE8E8);
    return const Color(0xFFF3F4F6);
  }

  Color _iconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFF4285F4);
    if (n.contains('transit')) return const Color(0xFFE65100);
    if (n.contains('bus')) return const Color(0xFF9C27B0);
    if (n.contains('tesla')) return const Color(0xFFD32F2F);
    return const Color(0xFF9CA3AF);
  }

  Widget _buildPlaceholder(Vehicle vehicle) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _iconBgColor(vehicle.name),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _vehicleIcon(vehicle.name),
        size: 64,
        color: _iconColor(vehicle.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selected vehicle to handle updates (e.g. name change)
    final vehicle = ref.watch(selectedVehicleProvider) ?? this.vehicle;
    final pos = vehicle.position;
    final addressAsync = pos != null
        ? ref.watch(reverseGeocodeProvider(LatLng(pos.lat, pos.lon)))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détails du véhicule'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier le véhicule',
            onPressed: () => _showEditDialog(context, ref, vehicle),
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Vehicle Image Mockup
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: vehicle.imageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Image.network(
                          vehicle.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(vehicle),
                        ),
                      )
                    : _buildPlaceholder(vehicle),
              ),
            ),

            // Name & Plate
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showEditDialog(context, ref, vehicle),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      if (vehicle.plate != null && vehicle.plate!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              vehicle.plate!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        'S/N: ${vehicle.serialNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2x2 Grid Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Batterie',
                    value: pos?.battery != null ? '${pos!.battery}%' : '--',
                    trailing: Text(
                      (pos?.battery ?? 0) > 20 ? 'OK' : 'Faible',
                      style: TextStyle(
                        color: (pos?.battery ?? 0) > 20
                            ? AppColors.primary
                            : AppColors.statusAlert,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    progress: (pos?.battery ?? 0) / 100,
                    color: (pos?.battery ?? 0) > 20
                        ? AppColors.primary
                        : AppColors.statusAlert,
                  ),
                  _StatCard(
                    icon: Icons.power_settings_new_rounded,
                    label: 'Moteur',
                    value: pos?.ignition == true ? 'Allumé' : 'Éteint',
                    trailing: const SizedBox(),
                    progress: pos?.ignition == true ? 1.0 : 0.0,
                    color: pos?.ignition == true
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  _StatCard(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: 'Signal GPS',
                    value: (pos?.rssi ?? 31) > 20 ? 'Excellent' : 'Faible',
                    trailing: const Text(
                      'Fort',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    progress: (pos?.rssi ?? 25) / 31,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    icon: Icons.access_time_rounded,
                    label: 'Màj',
                    value: vehicle.lastUpdate != null
                        ? timeago.format(vehicle.lastUpdate!)
                        : 'Inconnu',
                    trailing: Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.centerRight,
                      child: StatusBadge(status: vehicle.status),
                    ),
                    progress: 1.0,
                    color: AppColors.statusAlert,
                  ),
                ],
              ),
            ),

            // Map Preview
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (pos != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Switch to the main Map tab
                          ref.read(activeTabProvider.notifier).state = 1;
                          ref.read(selectedVehicleIdProvider.notifier).state =
                              vehicle.id;
                          // Close the detail view to return to the shell
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
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(pos.lat, pos.lon),
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Address Overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  addressAsync?.when(
                                        data: (addr) => Text(
                                          addr ??
                                              pos?.address ??
                                              'Position inconnue',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        loading: () => const Text(
                                          'Localisation...',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        error: (_, __) => const Text(
                                          'Position inconnue',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ) ??
                                      const Text(
                                        'Position inconnue',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                  Text(
                                    'Updated ${vehicle.lastUpdate != null ? timeago.format(vehicle.lastUpdate!) : 'just now'}',
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.statusAlert,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verrouillage à distance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Appuyer pour sécuriser',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Switch(
                      value: false,
                      onChanged: null, // Disabled in mockup
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.statusAlert.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.power_settings_new_rounded,
                        color: AppColors.statusAlert,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Coupure d\'urgence',
                        style: TextStyle(
                          color: AppColors.statusAlert,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final nameController = TextEditingController(text: vehicle.name);
    final plateController = TextEditingController(text: vehicle.plate ?? '');
    final serialController = TextEditingController(text: vehicle.serialNumber);
    final imageController = TextEditingController(text: vehicle.imageUrl ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le véhicule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du véhicule',
                  hintText: 'ex. Toyota RAV4',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation',
                  hintText: 'ex. ABC-1234',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: serialController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de série / IMEI',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'URL de la photo',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'uniqueId': serialController.text,
                'attributes': {
                  'plate': plateController.text,
                  'imageUrl': imageController.text,
                },
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref
            .read(vehiclesProvider.notifier)
            .updateVehicle(vehicle.id, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Véhicule mis à jour')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de mise à jour : $e')),
          );
        }
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final double progress;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (trailing != null) trailing!,
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
