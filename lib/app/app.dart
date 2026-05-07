import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/biometric_gate.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/settings_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FintrackApp extends ConsumerStatefulWidget {
  const FintrackApp({super.key});

  @override
  ConsumerState<FintrackApp> createState() => _FintrackAppState();
}

class _FintrackAppState extends ConsumerState<FintrackApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final useDynamic = ref.watch(settingsProvider).useDynamicColor;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useLightDyn = useDynamic ? lightDynamic : null;
        final useDarkDyn = useDynamic ? darkDynamic : null;
        return MaterialApp.router(
          title: 'FinTrack Pro',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(dynamic: useLightDyn),
          darkTheme: AppTheme.dark(dynamic: useDarkDyn),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: _router,
          builder: (context, child) => BiometricGate(child: child!),
        );
      },
    );
  }
}
