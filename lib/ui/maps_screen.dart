import 'dart:async';

import 'package:background_location/models/location_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final List<LocationPoint> points;
  const MapScreen({super.key, required this.points});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const LatLng _defaultTarget = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  late final CameraPosition _initialCameraPosition;
  late final Polyline _polyline;
  late final Set<Marker> _markers;
  late final Set<Circle> _circles;

  @override
  void initState() {
    final routePoints = _buildRoutePoints(widget.points);
    final target = routePoints.isNotEmpty ? routePoints.last : _defaultTarget;

    _initialCameraPosition = CameraPosition(target: target, zoom: 14.4746);
    _polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: routePoints,
    );
    _markers = {
      if (routePoints.isNotEmpty)
        Marker(
          markerId: const MarkerId('latest_location'),
          position: routePoints.last,
        ),
    };
    _circles = _buildPointCircles(routePoints);

    super.initState();
  }

  List<LatLng> _buildRoutePoints(List<LocationPoint> points) {
    final validPoints = points
        .where((point) => point.error == LocationError.none)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    return _removeDuplicateLatLng(validPoints);
  }

  List<LatLng> _removeDuplicateLatLng(List<LatLng> points) {
    if (points.isEmpty) return [];

    final filtered = <LatLng>[points.first];
    for (int i = 1; i < points.length; i++) {
      final prev = filtered.last;
      final curr = points[i];
      if (prev.latitude != curr.latitude || prev.longitude != curr.longitude) {
        filtered.add(curr);
      }
    }
    return filtered;
  }

  Set<Circle> _buildPointCircles(List<LatLng> points) {
    final circles = <Circle>{};
    for (int i = 0; i < points.length; i++) {
      circles.add(
        Circle(
          circleId: CircleId('route_point_$i'),
          center: points[i],
          radius: 3,
          fillColor: Colors.blueAccent,
          strokeColor: Colors.white,
          strokeWidth: 1,
        ),
      );
    }
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition,
        polylines: {_polyline},
        markers: _markers,
        circles: _circles,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
