import 'package:hive/hive.dart';

class BudgetModel extends HiveObject {
  BudgetModel({
    required this.id,
    required this.monthlyLimit,
    required this.currency,
    required this.periodStart,
  });

  final String id;
  double monthlyLimit;
  String currency;
  DateTime periodStart;

  BudgetModel copyWith({
    double? monthlyLimit,
    String? currency,
    DateTime? periodStart,
  }) {
    return BudgetModel(
      id: id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currency: currency ?? this.currency,
      periodStart: periodStart ?? this.periodStart,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'monthlyLimit': monthlyLimit,
        'currency': currency,
        'periodStart': periodStart.toIso8601String(),
      };

  static BudgetModel fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      currency: json['currency'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
    );
  }
}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 4;

  @override
  BudgetModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      id: fields[0] as String,
      monthlyLimit: fields[1] as double,
      currency: fields[2] as String,
      periodStart: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monthlyLimit)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.periodStart);
  }
}
