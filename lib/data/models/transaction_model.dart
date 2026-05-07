import 'package:hive/hive.dart';

class TransactionModel extends HiveObject {
  TransactionModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.receiptPath,
    this.recurringRuleId,
    this.isIncome = false,
  });

  final String id;
  double amount;
  String categoryId;
  DateTime date;
  String? notes;
  String? receiptPath;
  String? recurringRuleId;
  bool isIncome;
  DateTime createdAt;
  DateTime updatedAt;

  TransactionModel copyWith({
    double? amount,
    String? categoryId,
    DateTime? date,
    String? notes,
    String? receiptPath,
    String? recurringRuleId,
    bool? isIncome,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'notes': notes,
        'receiptPath': receiptPath,
        'recurringRuleId': recurringRuleId,
        'isIncome': isIncome,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static TransactionModel fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      receiptPath: json['receiptPath'] as String?,
      recurringRuleId: json['recurringRuleId'] as String?,
      isIncome: json['isIncome'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryId: fields[2] as String,
      date: fields[3] as DateTime,
      notes: fields[4] as String?,
      receiptPath: fields[5] as String?,
      recurringRuleId: fields[6] as String?,
      isIncome: (fields[7] as bool?) ?? false,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.receiptPath)
      ..writeByte(6)
      ..write(obj.recurringRuleId)
      ..writeByte(7)
      ..write(obj.isIncome)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }
}
