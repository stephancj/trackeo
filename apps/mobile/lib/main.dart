import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_view.dart';
import 'features/payments/views/payment_return_view.dart';
import 'features/security/views/public_tracking_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // M1 — Locale française pour timeago (ex: "Arrêté il y a 3 min")
  timeago.setLocaleMessages('fr', timeago.FrMessages());

  // OneSignal — App ID public (safe à hardcoder, pas un secret)
  const oneSignalAppId = 'b08553a3-c59a-49c7-8097-a23a704527bc';
  OneSignal.initialize(oneSignalAppId);
  // La permission est demandée depuis le bouton des paramètres. Sur iOS PWA,
  // la boîte native doit impérativement suivre une action explicite de l'utilisateur.

  // M4 — Remplace l'écran rouge Flutter par un fallback propre
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _AppErrorWidget(message: details.exceptionAsString());
  };

  runApp(
    const ProviderScope(
      child: IooehApp(),
    ),
  );
}

class IooehApp extends ConsumerStatefulWidget {
  const IooehApp({super.key});

  @override
  ConsumerState<IooehApp> createState() => _IooehAppState();
}

class _IooehAppState extends ConsumerState<IooehApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? linksSubscription;

  @override
  void initState() {
    super.initState();
    linksSubscription = AppLinks().uriLinkStream.listen((uri) {
      if (uri.host != 'app.iooeh.com') return;
      final route = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(route);
      });
    });
  }

  @override
  void dispose() {
    linksSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'iooeh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path.startsWith('/track/')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PublicTrackingView(
              token: uri.pathSegments.length > 1 ? uri.pathSegments[1] : '',
            ),
          );
        }
        if (uri.path == '/payment/return') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PaymentReturnView(
              reference: uri.queryParameters['reference'] ?? '',
              hintedStatus: uri.queryParameters['status'] ?? 'pending',
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => switch (auth.status) {
            AuthStatus.loading => const _SplashScreen(),
            AuthStatus.authenticated => const AppShell(),
            AuthStatus.unauthenticated => const LoginView(),
          },
        );
      },
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
// Flutter test
// test web+ios
// trigger mobile
