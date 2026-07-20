import 'dart:async';
import 'dart:io';

import 'package:chronex/base/model/bluetooth_state.dart';
import 'package:chronex/base/model/characteristic_data.dart';
import 'package:chronex/model/ble_uuids.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothNotifier extends AsyncNotifier<BLEState> {
  StreamSubscription<BluetoothAdapterState>? _subscription;
  StreamSubscription? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  BluetoothDevice? _device;
  final Map<Guid, BluetoothCharacteristic> _charCache = {};

  bool? _supported;
  bool _connecting = false;

  @override
  Future<BLEState> build() async {
    await _checkBluetoothSupport();
    await _requestBluetoothPermissions();

    final adapter = await FlutterBluePlus.adapterState.first;

    _subscription = FlutterBluePlus.adapterState.listen((sub) async {
      state = AsyncData(state.value?.copyWith(adapterState: sub) ?? BLEState(adapterState: sub, isScanning: false));

      if (sub == BluetoothAdapterState.off && Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    });

    _scanSub = FlutterBluePlus.isScanning.listen((scanning) {
      final current = state.value;
      if (current == null) return;

      state = AsyncData(current.copyWith(isScanning: scanning));
    });

    ref.onDispose(() {
      _subscription?.cancel();
      _scanSub?.cancel();
      _connectionSub?.cancel();
      disconnectFromDevice();
    });

    return BLEState(adapterState: adapter, isScanning: FlutterBluePlus.isScanningNow);
  }

  Future<void> _checkBluetoothSupport() async {
    _supported ??= await FlutterBluePlus.isSupported;

    if (!_supported!) {
      // throw Exception("Bluetooth not supported");
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    final statuses = await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    final granted = statuses.values.every((status) => status.isGranted);

    if (!granted) {
      final permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

      if (permanentlyDenied) {
        openAppSettings();
      }

      throw Exception("Bluetooth permissions denied");
    }
  }

Future<void> startScanning() async {
    if (FlutterBluePlus.isScanningNow) return;
    await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first;

    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [BleUuids.service],  
    );
}

  bool isChronexDevice(ScanResult result) {
    final String advName = result.advertisementData.advName.trim().toLowerCase();
    final String platformName = result.device.platformName.trim().toLowerCase();

    if (advName.contains('chronex') || platformName.contains('chronex')) {
      return true;
    }

    final String targetUuid = BleUuids.service.toString().toLowerCase().replaceAll('-', '');

    for (final uuid in result.advertisementData.serviceUuids) {
      final String cleanUuid = uuid.toString().toLowerCase().replaceAll('-', '');
      if (cleanUuid == targetUuid) {
        return true;
      }
    }

    return false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    if (state.value?.connectionState == BluetoothConnectionState.connected) {
      return;
    }

    if (_connecting) return;
    _connecting = true;

    try {
      await device.connect(license: License.free, timeout: const Duration(seconds: 15));

      _connectionSub?.cancel();

      _connectionSub = device.connectionState.listen((connectionState) {
        _device = device;
        state = AsyncData(state.value!.copyWith(connectionState: connectionState));
      });
      if (Platform.isAndroid) await device.requestMtu(512);
      await discoverServices();
    } catch (e) {
      state = AsyncData(state.value!.copyWith(connectionState: BluetoothConnectionState.disconnected));

      rethrow;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnectFromDevice() async {
    final device = _device;

    if (device == null) return;

    await device.disconnect();
  }

  Future<void> discoverServices() async {
    final device = _device;
    if (device == null) return;

    final List<BluetoothService> services = await device.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        _charCache[c.uuid] = c;
      }
    }
    state = AsyncData(state.value!.copyWith(services: services));
  }

  Stream<CharacteristicData> subscribeTo(Guid id) async* {
    final char = _charCache[id];
    if (char == null) return;

    await char.setNotifyValue(true);

    await for (final value in char.onValueReceived) {
      yield CharacteristicData(uuid: char.uuid, value: value);
    }
  }

  Future<void> writeTo(Guid id, List<int> value) async {
    final char = _charCache[id];
    if (char == null) {
      throw Exception("Characteristic not found: $id");
    }
    await char.write(value);
  }
}

final bluetoothProvider = AsyncNotifierProvider<BluetoothNotifier, BLEState>(BluetoothNotifier.new);

final scanResultsProvider = StreamProvider.autoDispose<List<ScanResult>>((ref) {
  return FlutterBluePlus.scanResults;
});
