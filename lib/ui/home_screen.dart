import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:background_location/models/location_point.dart';
import 'package:background_location/providers/location_providers.dart';
import 'package:background_location/services/location_service.dart';
import 'package:background_location/ui/maps_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isServiceRunning = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      updateServiceStatus();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(recentLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Route'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 17, bottom: 12),
              child: Text(
                'Showing last 10 location history',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        actions: [
          locations.when(
            data: (List<LocationPoint> data) {
              return data.isEmpty
                  ? SizedBox.shrink()
                  : IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return MapScreen(points: data);
                            },
                          ),
                        );
                      },
                      icon: Icon(Icons.map),
                    );
            },
            error: (Object error, StackTrace stackTrace) {
              return SizedBox.shrink();
            },
            loading: () {
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isServiceRunning) ...[
            FilledButton(
              onPressed: () async {
                final bool hasPermission = await _checkPermissions();
                if (hasPermission) {
                  await LocationService.start();
                  setState(() {
                    isServiceRunning = true;
                  });
                }
              },
              child: const Text('Start Tracking'),
            ),
          ] else ...[
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: () {
                LocationService.stop();
                setState(() {
                  isServiceRunning = false;
                });
              },
              child: const Text('Stop Tracking'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: locations.when(
              data: (data) => data.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No Records Found',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'New record will display every 5 minutes if you start tracking',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: data.length,
                      itemBuilder: (_, i) => ListTile(
                        onTap: () {
                          openMap(
                            latitude: data[i].latitude,
                            longitude: data[i].longitude,
                          );
                        },
                        leading: Icon(Icons.location_pin),
                        trailing: Icon(Icons.chevron_right),
                        dense: true,
                        title: Text(
                          '#${data[i].id}\n${data[i].error == LocationError.none ? '${data[i].latitude}, ${data[i].longitude} (Accuracy: ${data[i].accuracyLabel})' : data[i].error}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),

                        subtitle: Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(data[i].timestamp.toLocal()),
                        ),
                      ),
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider();
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlwaysPermissionSheet() async {
    final title = Platform.isIOS
        ? 'Allow Always Location'
        : 'Allow All The Time';
    final message = Platform.isIOS
        ? 'To track in background, set location permission to "Always" in app settings.'
        : 'To track in background, set location permission to "Allow all the time" in app settings.';

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPermissionSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Permission Needed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Location permission is permanently denied. Open app settings to allow background tracking.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkPermissions() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable (GPS) location services first.'),
          ),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background tracking started.')),
        );
      }
      await requestIgnoreBatteryOptimization(
        'com.himanshu.background_location',
      );
      return true;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await _showPermissionSettingsSheet();
      }
      return false;
    }

    if (permission == LocationPermission.whileInUse) {
      if (mounted) {
        await _showAlwaysPermissionSheet();
      }
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission not granted.')),
      );
    }
    return false;
  }

  Future<void> updateServiceStatus() async {
    final value = await FlutterBackgroundService().isRunning();
    setState(() {
      isServiceRunning = value;
    });
  }

  Future<void> requestIgnoreBatteryOptimization(String packageName) async {
    if (!Platform.isAndroid) return;

    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:$packageName',
    );
    await intent.launch();
  }

  Future<void> openMap({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri;

    if (Platform.isIOS) {
      // Apple Maps
      uri = Uri.parse('https://maps.apple.com/?ll=$latitude,$longitude');
    } else {
      // Google Maps (Android)
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open the map.';
    }
  }
}
