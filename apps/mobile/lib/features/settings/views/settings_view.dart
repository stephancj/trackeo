import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/views/reports_view.dart';
import 'alert_settings_view.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ── Main View ─────────────────────────────────────────────────────────────────

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Profil mis à jour'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      // M3 — Message générique : ne pas exposer les détails techniques à l'utilisateur.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Impossible de sauvegarder. Réessayez.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.statusAlert,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    final user = ref.read(authProvider).user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final displayName =
        (user?.name?.isNotEmpty ?? false) ? user!.name! : user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                'Modifier',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _cancelEdit,
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile hero ──────────────────────────────────────────────
              _ProfileCard(
                displayName: displayName,
                email: user?.email ?? '',
                role: user?.role,
                isEditing: _isEditing,
                nameController: _nameController,
                phoneController: _phoneController,
                phone: user?.phone,
                isSaving: _isSaving,
                onSave: _saveProfile,
              ),

              const SizedBox(height: 28),

              // ── Fonctionnalités ───────────────────────────────────────────
              _SectionLabel('FONCTIONNALITÉS'),
              _MenuSection(
                children: [
                  _MenuTile(
                    icon: Icons.bar_chart_rounded,
                    iconBg: const Color(0xFF5B8DEF),
                    title: 'Rapports de conduite',
                    subtitle: 'Trajets, vitesse, inactivité',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReportsView()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.notifications_active_rounded,
                    iconBg: AppColors.primary,
                    title: 'Alertes',
                    subtitle: 'Push, WhatsApp, seuils',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlertSettingsView()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Compte ────────────────────────────────────────────────────
              _SectionLabel('COMPTE'),
              _MenuSection(
                children: [
                  _InfoTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFF8B5CF6),
                    label: 'Rôle',
                    value: user?.role ?? '-',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Logout button (destructive, outside the group)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LogoutTile(onTap: () => _showLogoutDialog(context)),
              ),

              const SizedBox(height: 40),

              // ── Version ───────────────────────────────────────────────────
              Center(
                child: Text(
                  'Trackeo v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.statusAlert),
            child: const Text('Déconnexion',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String? role;
  final String? phone;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isSaving;
  final VoidCallback onSave;

  const _ProfileCard({
    required this.displayName,
    required this.email,
    required this.role,
    required this.phone,
    required this.isEditing,
    required this.nameController,
    required this.phoneController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Avatar + info row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4ECB8D), Color(0xFF2BA870)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _initials(displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (phone != null && phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                      if (role == 'admin') ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Edit fields (animated)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isEditing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone WhatsApp',
                          hintText: '+261341234567',
                          prefixIcon:
                              Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (!v.startsWith('+') && !v.startsWith('0')) {
                              return 'Format : +261341234567';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : onSave,
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Menu Section ──────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                const Divider(height: 1, indent: 62, endIndent: 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 19),
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
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Tile (non-tappable row) ──────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logout Tile ───────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.statusAlert.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.statusAlert.withValues(alpha: 0.2),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.statusAlert, size: 20),
            SizedBox(width: 8),
            Text(
              'Déconnexion',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.statusAlert,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
