import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/base/model/bluetooth_state.dart';
import 'package:chronex/base/theme/app_color.dart';
import 'package:chronex/base/theme/s_text_theme.dart';
import 'package:chronex/presentation/provider/bluetooth_provider.dart';
import 'package:chronex/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConsumerState<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends ConsumerState<ConnectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bluetoothProvider.notifier).discoverServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleAsync = ref.watch(bluetoothProvider);
    return bleAsync.when(
      data: (state) {
        final isConnected = state.connectionState == BluetoothConnectionState.connected;
        final isScanning = state.isScanning;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildStatusCard(state), 16.sBHh, if (isConnected) _buildServicesSection(state) else _buildDeviceList(isScanning)],
          ),
        );
      },
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildStatusCard(BLEState state) {
    final isConnected = state.connectionState == BluetoothConnectionState.connected;
    final isScanning = state.isScanning;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: isConnected ? AppColor.green : Colors.white54, size: 28),
              12.sBWw,
              Expanded(
                child: Text(isConnected ? 'Connected' : 'Disconnected', style: STextTheme.text22.copyWith(color: AppColor.white)),
              ),
              if (!isConnected)
                AppButton(
                  onPressed: () => ref.read(bluetoothProvider.notifier).startScanning(),
                  title: isScanning ? 'Scanning...' : 'Scan',
                  isDisabled: isScanning,
                  color: Colors.grey.shade100,
                  titleColor: AppColor.primary,
                  width: 120.w,
                  height: 40.h,
                  fontSize: 14,
                ),
            ],
          ),
          8.sBHh,
          Text('Adapter: ${state.adapterState.name}', style: STextTheme.text14.copyWith(color: Colors.white70)),
          if (isConnected) ...[
            8.sBHh,
            AppButton(
              onPressed: () => ref.read(bluetoothProvider.notifier).disconnectFromDevice(),
              title: 'Disconnect',
              isAlt: true,
              width: 160.w,
              height: 40.h,
              fontSize: 14,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList(bool isScanning) {
    final scanResults = ref.watch(scanResultsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Discovered Devices', style: STextTheme.text18),
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh scan', onPressed: () => ref.read(bluetoothProvider.notifier).startScanning()),
          ],
        ),
        scanResults.when(
          data: (results) {
            if (results.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: Center(
                  child: Text(
                    isScanning ? 'Scanning for Chronex devices...' : 'Tap Scan to discover devices',
                    style: STextTheme.text16.copyWith(color: AppColor.neutral),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                String displayName = result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Chronex';

                final device = result.device;
                return ListTile(
                  leading: const Icon(Icons.bluetooth_searching, color: AppColor.primary),
                  title: Text(displayName),
                  subtitle: Text(device.remoteId.str),
                  trailing: Text('${result.rssi} dBm'),
                  onTap: () async {
                    await ref.read(bluetoothProvider.notifier).connectToDevice(device);
                  },
                );
              },
              separatorBuilder: (_, _) => const Divider(height: 1),
            );
          },
          error: (e, _) => Center(child: Text('Error: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BLEState state) {
    final services = state.services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Services & Characteristics', style: STextTheme.text18),
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh services', onPressed: () => ref.read(bluetoothProvider.notifier).discoverServices()),
          ],
        ),
        if (services == null || services.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Center(
              child: Text('No services discovered', style: STextTheme.text16.copyWith(color: AppColor.neutral)),
            ),
          )
        else
          ...services.map((s) => _serviceTile(s)),
      ],
    );
  }

  Widget _serviceTile(BluetoothService service) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: AppColor.neutral50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service: ${service.uuid.toString()}', style: STextTheme.text14.copyWith(fontWeight: FontWeight.w600)),
          8.sBHh,
          ...service.characteristics.map(
            (c) => Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Text('  ${c.uuid.toString()} [${c.properties.toString()}]', style: STextTheme.text12.copyWith(color: AppColor.neutral)),
            ),
          ),
        ],
      ),
    );
  }
}
