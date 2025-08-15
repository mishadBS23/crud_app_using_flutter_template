import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/di/dependency_injection.dart';
import 'src/core/logger/riverpod_log.dart';
import 'src/presentation/core/router/router.dart';
import 'src/presentation/core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      observers: [RiverpodObserver()],
      overrides: [
        // preferred: completes the FutureProvider immediately
        sharedPreferencesProvider.overrideWith((ref) async => prefs),

        // (alt) also works in many setups:
        // sharedPreferencesProvider.overrideWithValue(AsyncData(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: MaterialApp.router(
        theme: context.lightTheme,
        darkTheme: context.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: ref.read(goRouterProvider),
      ),
    );
  }
}
