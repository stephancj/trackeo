import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OneSignal — App ID public (safe à hardcoder, pas un secret)
  const oneSignalAppId = 'b08553a3-c59a-49c7-8097-a23a704527bc';
  OneSignal.initialize(oneSignalAppId);
  // Demande permission push (false = non-bloquant, la bannière apparaît plus tard)
  OneSignal.Notifications.requestPermission(false);

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
