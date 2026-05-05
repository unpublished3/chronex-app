import 'dart:typed_data';

// parsed from BLE to match the C struct
class MotionData {
  final int steps;
  final double cadence;
  MotionData({required this.steps, required this.cadence});
  factory MotionData.fromBytes(List<int> bytes) {
    final buffer = Uint8List.fromList(bytes).buffer;
    final data = ByteData.view(buffer);
    final steps = data.getUint32(0, Endian.little);
    final cadence = data.getFloat32(4, Endian.little);
    return MotionData(steps: steps, cadence: cadence);
  }
}

class HeartRateData {
  final int bpm;
  HeartRateData({required this.bpm});
  factory HeartRateData.fromBytes(List<int> bytes) {
    return HeartRateData(bpm: bytes[1]); // byte[0] is flags, byte[1] is HR
  }
}
