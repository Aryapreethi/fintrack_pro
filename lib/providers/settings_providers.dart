import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/currency_formatter.dart';
import '../data/models/settings_model.dart';
import 'database_providers.dart';

final settingsStreamProvider = StreamProvider<SettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch();
});

final settingsProvider = Provider<SettingsModel>((ref) {
  final s = ref.watch(settingsStreamProvider);
  return s.maybeWhen(data: (v) => v, orElse: SettingsModel.new);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(settingsProvider).themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

final localeProvider = Provider<Locale>((ref) {
  final tag = ref.watch(settingsProvider).locale;
  return Locale(tag);
});

final currencyFormatterProvider = Provider<CurrencyFormatter>((ref) {
  final s = ref.watch(settingsProvider);
  return CurrencyFormatter(
    localeTag: s.locale,
    currencyCode: s.currencyCode,
  );
});

final reducedMotionProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).reducedMotion;
});
