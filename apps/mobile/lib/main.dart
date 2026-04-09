import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/theme/app_theme.dart';
import 'core/navigation/app_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // M1 — Locale française pour timeago (ex: "Arrêté il y a 3 min")
  timeago.setLocaleMessages('fr', timeago.FrMessages());

  // OneSignal — App ID public (safe à hardcoder, pas un secret)
  const oneSignalAppId = 'b08553a3-c59a-49c7-8097-a23a704527bc';
  OneSignal.initialize(oneSignalAppId);
  // Demande permission push (false = non-bloquant, la bannière apparaît plus tard)
  OneSignal.Notifications.requestPermission(false);

  // M4 — Remplace l'écran rouge Flutter par un fallback propre
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _AppErrorWidget(message: details.exceptionAsString());
  };

  runApp(
    const ProviderScope(
      child: TrackeoApp(),
    ),
  );
}

class TrackeoApp extends ConsumerWidget {
  const TrackeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Trackeo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (auth.status) {
        AuthStatus.loading => const _SplashScreen(),
        AuthStatus.authenticated => const AppShell(),
        AuthStatus.unauthenticated => const LoginView(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// M4 — Fallback propre si un widget crash (remplace l'écran rouge Flutter)
class _AppErrorWidget extends StatelessWidget {
  final String message;
  const _AppErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Une erreur est survenue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez redémarrer l\'application.',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
