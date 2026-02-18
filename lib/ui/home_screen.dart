import 'package:background_location/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(recentLocationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Route')),
      body: locations.when(
        data: (data) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) => ListTile(
            title: Text('${data[i].latitude}, ${data[i].longitude}'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(e.toString()),
      ),
    );
  }
}
