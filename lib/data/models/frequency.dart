import 'package:hive/hive.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
}

class FrequencyAdapter extends TypeAdapter<Frequency> {
  @override
  final int typeId = 3;

  @override
  Frequency read(BinaryReader reader) {
    final index = reader.readByte();
    if (index < 0 || index >= Frequency.values.length) return Frequency.monthly;
    return Frequency.values[index];
  }

  @override
  void write(BinaryWriter writer, Frequency obj) {
    writer.writeByte(obj.index);
  }
}
