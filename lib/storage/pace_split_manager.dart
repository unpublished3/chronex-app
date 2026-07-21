import 'package:chronex/model/pace_split_data.dart';
import 'package:chronex/storage/hive_manager.dart';

class PaceSplitManager {
  PaceSplitManager._();
  static final PaceSplitManager _instance = PaceSplitManager._();
  factory PaceSplitManager() => _instance;

  final HiveManager _hiveManager = HiveManager('paceSplitBox');

  Future<void> savePaceSplit(PaceSplitData data) async {
    await _hiveManager.write(data.runKey.toString(), data);
  }

  Future<PaceSplitData?> getForRun(dynamic runKey) async {
    final data = await _hiveManager.read(runKey.toString());
    return data as PaceSplitData?;
  }
}
