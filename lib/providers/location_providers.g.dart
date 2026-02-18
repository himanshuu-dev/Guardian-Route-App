// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository provider

@ProviderFor(locationRepository)
final locationRepositoryProvider = LocationRepositoryProvider._();

/// Repository provider

final class LocationRepositoryProvider
    extends
        $FunctionalProvider<
          LocationRepository,
          LocationRepository,
          LocationRepository
        >
    with $Provider<LocationRepository> {
  /// Repository provider
  LocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationRepository create(Ref ref) {
    return locationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationRepository>(value),
    );
  }
}

String _$locationRepositoryHash() =>
    r'2526190538b40cd146beb2ca33ce901ef47fe5f8';

/// Recent locations stream provider

@ProviderFor(recentLocations)
final recentLocationsProvider = RecentLocationsProvider._();

/// Recent locations stream provider

final class RecentLocationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocationPoint>>,
          List<LocationPoint>,
          Stream<List<LocationPoint>>
        >
    with
        $FutureModifier<List<LocationPoint>>,
        $StreamProvider<List<LocationPoint>> {
  /// Recent locations stream provider
  RecentLocationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentLocationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentLocationsHash();

  @$internal
  @override
  $StreamProviderElement<List<LocationPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LocationPoint>> create(Ref ref) {
    return recentLocations(ref);
  }
}

String _$recentLocationsHash() => r'5dfcc853d945a29b4d21b91cf55641077c6338bf';
