import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/map/views/map_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TrackeoApp(),
    ),
  );
}

class TrackeoApp extends StatelessWidget {
  const TrackeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackeo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MapView(),
    );
  }
}
