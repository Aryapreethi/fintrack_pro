import 'package:hive/hive.dart';

import '../datasources/hive_database.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final HiveDatabase _db;

  Box<SettingsModel> get _box => _db.settings;
  String get _key => HiveDatabase.settingsKey;

  SettingsModel current() => _box.get(_key) ?? SettingsModel();

  Stream<SettingsModel> watch() async* {
    yield current();
    yield* _box.watch(key: _key).map((_) => current());
  }

  Future<void> save(SettingsModel s) async => _box.put(_key, s);

  Future<void> update({
    String? themeMode,
    String? locale,
    bool? biometricEnabled,
    String? currencyCode,
    DateTime? lastBackupAt,
    bool? reducedMotion,
    bool? useDynamicColor,
    bool? onboardingComplete,
  }) async {
    final c = current();
    final next = SettingsModel(
      themeMode: themeMode ?? c.themeMode,
      locale: locale ?? c.locale,
      biometricEnabled: biometricEnabled ?? c.biometricEnabled,
      currencyCode: currencyCode ?? c.currencyCode,
      lastBackupAt: lastBackupAt ?? c.lastBackupAt,
      reducedMotion: reducedMotion ?? c.reducedMotion,
      useDynamicColor: useDynamicColor ?? c.useDynamicColor,
      onboardingComplete: onboardingComplete ?? c.onboardingComplete,
    );
    await save(next);
  }
}
