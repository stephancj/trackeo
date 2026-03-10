import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AlertSettingsView extends ConsumerStatefulWidget {
  const AlertSettingsView({super.key});

  @override
  ConsumerState<AlertSettingsView> createState() => _AlertSettingsViewState();
}

class _AlertSettingsViewState extends ConsumerState<AlertSettingsView> {
  late bool _alertsEnabled;
  late bool _sosAlerts;
  late bool _lowBattery;
  late bool _speedLimit;
  late bool _pushNotification;
  late bool _whatsAppNotification;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadFromUser();
  }

  void _loadFromUser() {
    final user = ref.read(authProvider).user;
    _alertsEnabled = user?.alertsEnabled ?? true;
    _sosAlerts = user?.alertSos ?? true;
    _lowBattery = user?.alertLowBattery ?? true;
    _speedLimit = user?.alertSpeedLimit ?? false;
    _pushNotification = user?.alertViaPush ?? true;
    _whatsAppNotification = user?.alertViaWhatsapp ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final hasPhone = user?.phone?.isNotEmpty == true;

    if (!_initialized && user != null) {
      _alertsEnabled = user.alertsEnabled;
      _sosAlerts = user.alertSos;
      _lowBattery = user.alertLowBattery;
      _speedLimit = user.alertSpeedLimit;
      _pushNotification = user.alertViaPush;
      _whatsAppNotification = user.alertViaWhatsapp;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres d\'alertes'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('CONTRÔLE GÉNÉRAL'),
            const SizedBox(height: 12),
            _buildMasterSwitch(),
            const SizedBox(height: 24),
            _buildSectionHeader('TYPES D\'ALERTES'),
            const SizedBox(height: 12),
            _buildAlertTypes(),
            const SizedBox(height: 24),
            _buildSectionHeader('CANAUX DE NOTIFICATION'),
            const SizedBox(height: 12),
            _buildNotificationMethods(hasPhone),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMasterSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildSettingItem(
        icon: Icons.notifications_active_rounded,
        iconColor: _alertsEnabled ? AppColors.primary : AppColors.textHint,
        iconBg: _alertsEnabled
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.divider.withValues(alpha: 0.3),
        title: 'Activer les alertes',
        subtitle: 'Activer ou désactiver toutes les notifications',
        value: _alertsEnabled,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() => _alertsEnabled = v);
        },
        isEnabled: true,
      ),
    );
  }

  Widget _buildAlertTypes() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.warning_rounded,
            iconColor: Colors.red,
            iconBg: Colors.red.withValues(alpha: 0.1),
            title: 'Alertes SOS',
            subtitle: 'Notification immédiate en cas d\'urgence',
            value: _sosAlerts,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _sosAlerts = v);
            },
            isEnabled: _alertsEnabled,
          ),
          const Divider(height: 1, indent: 64, color: AppColors.divider),
          _buildSettingItem(
            icon: Icons.battery_alert_rounded,
            iconColor: Colors.amber,
            iconBg: Colors.amber.withValues(alpha: 0.1),
            title: 'Batterie faible',
            subtitle: 'En dessous de 20% de charge',
            value: _lowBattery,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _lowBattery = v);
            },
            isEnabled: _alertsEnabled,
          ),
          const Divider(height: 1, indent: 64, color: AppColors.divider),
          _buildSettingItem(
            icon: Icons.speed_rounded,
            iconColor: Colors.purple,
            iconBg: Colors.purple.withValues(alpha: 0.1),
            title: 'Excès de vitesse',
            subtitle: 'Dépassement de 120 km/h',
            value: _speedLimit,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _speedLimit = v);
            },
            isEnabled: _alertsEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationMethods(bool hasPhone) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            title: 'Notification push',
            subtitle: 'Recevoir les alertes via le navigateur',
            value: _pushNotification,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _pushNotification = v);
            },
            isEnabled: _alertsEnabled,
          ),
          const Divider(height: 1, indent: 64, color: AppColors.divider),
          _buildSettingItem(
            icon: Icons.chat_rounded,
            iconColor: Colors.green,
            iconBg: Colors.green.withValues(alpha: 0.1),
            title: 'WhatsApp',
            subtitle: hasPhone
                ? 'Recevoir les alertes via WhatsApp'
                : 'Ajoutez un numéro dans votre profil',
            value: _whatsAppNotification,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _whatsAppNotification = v);
            },
            isEnabled: _alertsEnabled && hasPhone,
            showWarning: !hasPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isEnabled,
    bool showWarning = false,
  }) {
    final effectiveValue = isEnabled ? value : false;
    final effectiveColor = isEnabled ? iconColor : AppColors.textHint;
    final effectiveBg = isEnabled
        ? iconBg
        : AppColors.divider.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: showWarning
                              ? Colors.orange
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    if (showWarning)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: effectiveValue,
              activeColor: iconColor,
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(authProvider.notifier)
          .updateAlertSettings(
            alertsEnabled: _alertsEnabled,
            alertSos: _sosAlerts,
            alertLowBattery: _lowBattery,
            alertSpeedLimit: _speedLimit,
            alertViaPush: _pushNotification,
            alertViaWhatsapp: _whatsAppNotification,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres d\'alertes enregistrés'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
