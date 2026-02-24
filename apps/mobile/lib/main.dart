import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_view.dart';

void main() {
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
