import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/vehicles/views/fleet_list_view.dart';
import '../../features/map/views/map_view.dart';
import '../../features/alerts/views/alerts_view.dart';
import '../../features/settings/views/settings_view.dart';

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
          SettingsView(),
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
              _NavItem(
                pageIndex: 0,
                icon: Icons.list_alt_outlined,
                activeIcon: Icons.list_alt,
                label: 'Flotte',
                activeTab: activeTab,
                onTap: () => onTabChanged(0),
              ),
              _NavItem(
                pageIndex: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Carte',
                activeTab: activeTab,
                onTap: () => onTabChanged(1),
              ),
              // FAB central
              Expanded(
                child: Center(
                  child: _AnimatedFab(
                    onTap: () => _showAddVehicleSnackbar(context),
                  ),
                ),
              ),
              _NavItem(
                pageIndex: 2,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Alertes',
                activeTab: activeTab,
                onTap: () => onTabChanged(2),
              ),
              _NavItem(
                pageIndex: 3,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Réglages',
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

// ── Animated FAB ─────────────────────────────────────────────────────────────

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedFab({required this.onTap});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
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
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ── Nav Item with bounce ──────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
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

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  bool get isActive => widget.activeTab == widget.pageIndex;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.25, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isActive && oldWidget.activeTab != widget.pageIndex) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (_, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive ? widget.activeIcon : widget.icon,
                  key: ValueKey(isActive),
                  color: isActive ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
