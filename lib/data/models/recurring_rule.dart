import 'package:hive/hive.dart';

import 'frequency.dart';

class RecurringRule extends HiveObject {
  RecurringRule({
    required this.id,
    required this.frequency,
    required this.startDate,
    required this.baseAmount,
    required this.categoryId,
    required this.lastGeneratedAt,
    this.endDate,
    this.notes,
    this.isIncome = false,
  });

  final String id;
  Frequency frequency;
  DateTime startDate;
  DateTime? endDate;
  double baseAmount;
  String categoryId;
  String? notes;
  bool isIncome;
  DateTime lastGeneratedAt;

  RecurringRule copyWith({
    Frequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    double? baseAmount,
    String? categoryId,
    String? notes,
    bool? isIncome,
    DateTime? lastGeneratedAt,
  }) {
    return RecurringRule(
      id: id,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      baseAmount: baseAmount ?? this.baseAmount,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      isIncome: isIncome ?? this.isIncome,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'baseAmount': baseAmount,
        'categoryId': categoryId,
        'notes': notes,
        'isIncome': isIncome,
        'lastGeneratedAt': lastGeneratedAt.toIso8601String(),
      };

  static RecurringRule fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['id'] as String,
      frequency: Frequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => Frequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      baseAmount: (json['baseAmount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      notes: json['notes'] as String?,
      isIncome: json['isIncome'] as bool? ?? false,
      lastGeneratedAt: DateTime.parse(json['lastGeneratedAt'] as String),
    );
  }
}

class RecurringRuleAdapter extends TypeAdapter<RecurringRule> {
  @override
  final int typeId = 2;

  @override
  RecurringRule read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return RecurringRule(
      id: fields[0] as String,
      frequency: fields[1] as Frequency,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime?,
      baseAmount: fields[4] as double,
      categoryId: fields[5] as String,
      notes: fields[6] as String?,
      isIncome: (fields[7] as bool?) ?? false,
      lastGeneratedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.baseAmount)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isIncome)
      ..writeByte(8)
      ..write(obj.lastGeneratedAt);
  }
}
