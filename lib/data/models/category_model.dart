import 'package:hive/hive.dart';

class CategoryModel extends HiveObject {
  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isSystem = false,
    this.isIncome = false,
  });

  final String id;
  String name;
  int iconCodePoint;
  int colorValue;
  bool isSystem;
  bool isIncome;

  CategoryModel copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isIncome,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isSystem: isSystem,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isSystem': isSystem,
        'isIncome': isIncome,
      };

  static CategoryModel fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      isSystem: json['isSystem'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconCodePoint: fields[2] as int,
      colorValue: fields[3] as int,
      isSystem: (fields[4] as bool?) ?? false,
      isIncome: (fields[5] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconCodePoint)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isSystem)
      ..writeByte(5)
      ..write(obj.isIncome);
  }
}
