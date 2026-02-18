import 'package:background_location/providers/location_providers.dart';
import 'package:background_location/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _startTracking() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      await Geolocator.openLocationSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location services first.')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always) {
      await LocationService.start();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background tracking started.')),
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission not granted.')),
    );
  }

  Stream<bool> getServiceStatusStream() {
    return Stream.periodic(const Duration(seconds: 2), (count) {
      return count;
    }).asyncMap((token) async {
      return await FlutterBackgroundService().isRunning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(recentLocationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Route')),
      body: StreamBuilder(
        stream: getServiceStatusStream(),
        builder: (context, asyncSnapshot) {
          final running = asyncSnapshot.data ?? false;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!running)
                    ElevatedButton(
                      onPressed: _startTracking,
                      child: const Text('Start Tracking'),
                    ),
                  if (running)
                    ElevatedButton(
                      onPressed: () {
                        LocationService.stop();
                      },
                      child: const Text('Stop Tracking'),
                    ),
                ],
              ),
              Expanded(
                child: locations.when(
                  data: (data) => ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text('${data[i].latitude}, ${data[i].longitude}'),
                      subtitle: Text('${data[i].timestamp}(${data[i].error})'),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(e.toString()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
