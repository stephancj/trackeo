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
  late bool _lowBattery;
  late bool _speedLimit;
  late bool _pushNotification;
  late bool _whatsAppNotification;
  bool _isSaving = false;
  bool _isSubscribing = false;
  String _pushPermissionStatus = 'default';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadFromUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _pushPermissionStatus =
            ref.read(authProvider.notifier).pushPermissionStatus;
      });
    });
  }

  void _loadFromUser() {
    final user = ref.read(authProvider).user;
    _alertsEnabled = user?.alertsEnabled ?? true;
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
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
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
            _buildMasterSwitch(),
            const SizedBox(height: 28),
            _buildSectionHeader('TYPES D\'ALERTES',
                subtitle: 'Ce qui déclenche une alerte'),
            const SizedBox(height: 12),
            _buildAlertTypes(),
            const SizedBox(height: 28),
            _buildSectionHeader('CANAUX',
                subtitle: 'Comment vous êtes prévenu'),
            const SizedBox(height: 12),
            _buildNotificationMethods(hasPhone),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
          ),
        ],
      ],
    );
  }

  /// Carte hero : bascule maîtresse de toutes les alertes.
  Widget _buildMasterSwitch() {
    final on = _alertsEnabled;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: on
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2BA870), Color(0xFF13805A)],
              )
            : null,
        color: on ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: on ? null : Border.all(color: AppColors.divider),
        boxShadow: on
            ? [
                BoxShadow(
                  color: const Color(0xFF2BA870).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: on
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.divider.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              on
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: on ? Colors.white : AppColors.textHint,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'Activées — vous recevez les notifications'
                      : 'Désactivées — aucune notification',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: on
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: on,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _alertsEnabled = v);
            },
          ),
        ],
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

  Widget _buildPushSubscriptionCard() {
    final subscribed = _pushPermissionStatus == 'subscribed';
    final denied = _pushPermissionStatus == 'denied';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (subscribed ? Colors.green : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              subscribed
                  ? Icons.check_circle_rounded
                  : Icons.phone_iphone_rounded,
              color: subscribed ? Colors.green : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscribed
                      ? 'Cet iPhone est abonné'
                      : denied
                          ? 'Notifications refusées'
                          : 'Activer sur cet iPhone',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subscribed
                      ? 'Les alertes peuvent arriver sur cet appareil'
                      : denied
                          ? 'À réactiver dans les Réglages iOS'
                          : 'Autorisez les notifications de la PWA',
                  style: TextStyle(
                    fontSize: 12,
                    color: denied ? Colors.orange : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (subscribed)
            const Icon(Icons.verified_rounded, color: Colors.green, size: 22)
          else
            FilledButton(
              onPressed: _isSubscribing ? null : _subscribeToPush,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 38),
              ),
              child: _isSubscribing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Activer'),
            ),
        ],
      ),
    );
  }

  Future<void> _subscribeToPush() async {
    setState(() => _isSubscribing = true);

    var subscribed = false;
    try {
      subscribed = await ref.read(authProvider.notifier).subscribeToPush();
    } catch (_) {
      subscribed = false;
    }

    if (!mounted) return;
    final status = ref.read(authProvider.notifier).pushPermissionStatus;
    setState(() {
      _isSubscribing = false;
      _pushPermissionStatus = subscribed ? 'subscribed' : status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          subscribed
              ? 'Notifications activées sur cet iPhone.'
              : status == 'denied'
                  ? 'Autorisation refusée. Ouvrez Réglages > Notifications > iooeh.'
                  : 'Ouvrez iooeh depuis son icône sur l’écran d’accueil, puis réessayez.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: subscribed ? null : Colors.orange,
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
          _buildPushSubscriptionCard(),
          const Divider(height: 1, indent: 64, color: AppColors.divider),
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
    final effectiveBg =
        isEnabled ? iconBg : AppColors.divider.withValues(alpha: 0.3);

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
                    color:
                        isEnabled ? AppColors.textPrimary : AppColors.textHint,
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
                          color:
                              showWarning ? Colors.orange : AppColors.textHint,
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
      await ref.read(authProvider.notifier).updateAlertSettings(
            alertsEnabled: _alertsEnabled,
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’enregistrer les paramètres.'),
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
