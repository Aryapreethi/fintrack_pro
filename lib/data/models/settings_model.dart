import 'package:hive/hive.dart';

class SettingsModel extends HiveObject {
  SettingsModel({
    this.themeMode = 'system',
    this.locale = 'en',
    this.biometricEnabled = false,
    this.currencyCode = 'USD',
    this.lastBackupAt,
    this.reducedMotion = false,
    this.useDynamicColor = true,
    this.onboardingComplete = false,
  });

  String themeMode; // 'system' | 'light' | 'dark'
  String locale; // 'en' | 'hi'
  bool biometricEnabled;
  String currencyCode;
  DateTime? lastBackupAt;
  bool reducedMotion;
  bool useDynamicColor;
  bool onboardingComplete;

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'locale': locale,
        'biometricEnabled': biometricEnabled,
        'currencyCode': currencyCode,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
        'reducedMotion': reducedMotion,
        'useDynamicColor': useDynamicColor,
        'onboardingComplete': onboardingComplete,
      };

  static SettingsModel fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: json['themeMode'] as String? ?? 'system',
      locale: json['locale'] as String? ?? 'en',
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      lastBackupAt: json['lastBackupAt'] == null
          ? null
          : DateTime.parse(json['lastBackupAt'] as String),
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      useDynamicColor: json['useDynamicColor'] as bool? ?? true,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 5;

  @override
  SettingsModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      themeMode: (fields[0] as String?) ?? 'system',
      locale: (fields[1] as String?) ?? 'en',
      biometricEnabled: (fields[2] as bool?) ?? false,
      currencyCode: (fields[3] as String?) ?? 'USD',
      lastBackupAt: fields[4] as DateTime?,
      reducedMotion: (fields[5] as bool?) ?? false,
      useDynamicColor: (fields[6] as bool?) ?? true,
      onboardingComplete: (fields[7] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.locale)
      ..writeByte(2)
      ..write(obj.biometricEnabled)
      ..writeByte(3)
      ..write(obj.currencyCode)
      ..writeByte(4)
      ..write(obj.lastBackupAt)
      ..writeByte(5)
      ..write(obj.reducedMotion)
      ..writeByte(6)
      ..write(obj.useDynamicColor)
      ..writeByte(7)
      ..write(obj.onboardingComplete);
  }
}
