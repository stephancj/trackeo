import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/vehicles/views/fleet_list_view.dart';
import '../../features/map/views/map_view.dart';
import '../../features/alerts/views/alerts_view.dart';

/// Index de l'onglet actif : 0=List, 1=Map, 2=Alerts, 3=Settings
final activeTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: activeTab,
        children: const [
          FleetListView(),
          MapView(),
          AlertsView(),
          _PlaceholderView(icon: Icons.settings_outlined, label: 'Paramètres'),
        ],
      ),
      bottomNavigationBar: _TrackeoBottomNav(
        activeTab: activeTab,
        onTabChanged: (i) => ref.read(activeTabProvider.notifier).state = i,
      ),
    );
  }
}

// ── Bottom Navigation Bar ──────────────────────────────────────────────────

class _TrackeoBottomNav extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _TrackeoBottomNav({
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              // List
              _NavItem(
                pageIndex: 0,
                icon: Icons.list_alt_outlined,
                activeIcon: Icons.list_alt,
                label: 'List',
                activeTab: activeTab,
                onTap: () => onTabChanged(0),
              ),
              // Map
              _NavItem(
                pageIndex: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Map',
                activeTab: activeTab,
                onTap: () => onTabChanged(1),
              ),
              // FAB central
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showAddVehicleSnackbar(context),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              // Alerts
              _NavItem(
                pageIndex: 2,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Alerts',
                activeTab: activeTab,
                onTap: () => onTabChanged(2),
              ),
              // Settings
              _NavItem(
                pageIndex: 3,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                activeTab: activeTab,
                onTap: () => onTabChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVehicleSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajout de véhicule — disponible en V2'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int pageIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int activeTab;
  final VoidCallback onTap;

  const _NavItem({
    required this.pageIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeTab,
    required this.onTap,
  });

  bool get isActive => activeTab == pageIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder pour les écrans à venir ────────────────────────────────────

class _PlaceholderView extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderView({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Disponible en V2',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
