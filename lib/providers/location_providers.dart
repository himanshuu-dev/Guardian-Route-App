import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/location_repository.dart';
import '../models/location_point.dart';

part 'location_providers.g.dart';

@riverpod
LocationRepository locationRepository(Ref ref) {
  return LocationRepository();
}

@riverpod
Stream<List<LocationPoint>> recentLocations(Ref ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.watchRecent().take(10);
}
