import 'package:chronex/base/extensions/sizedbox_extension.dart';
import 'package:chronex/presentation/provider/bluetooth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return ref.watch(bluetoothProvider).when(
      data: (state) {
        final services = state.services;
        if (services == null || services.isEmpty) {
          return const Center(child: Text('No services discovered. Connect to a device first.'));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final service = services[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service: ${service.uuid.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...service.characteristics.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text('  Char: ${c.uuid.toString()} (${c.properties.toString()})'),
                  );
                }),
              ],
            );
          },
          separatorBuilder: (context, index) => 12.sBHh,
          itemCount: services.length,
        );
      },
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
