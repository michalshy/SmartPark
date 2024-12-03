import 'package:flutter/material.dart';
import 'position.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

// ignore: must_be_immutable
class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Position pos = Position(0.0, 0.0);
  bool _isNavigating = false;

  final _controller = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ));

  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupLocationListener();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.startLocationUpdating();
    } catch (e) {
      print('Error initializing MapController: $e');
    }
  }

  void _setupLocationListener() {
    _controller.listenerMapLongTapping.addListener(() {
      // Reapply markers when map updates
      _applyUserLocationMarker();
    });
  }

  Future<void> _applyUserLocationMarker() async {
    try {
      // Add the user location marker
      await _controller.addMarker(
        pos.position, // Use the GeoPoint from the `Position` class
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_history_rounded,
            color: Colors.red,
            size: 48,
          ),
        ),
      );

      // If navigating, add the direction arrow marker
      if (_isNavigating) {
        await _addDirectionArrow();
      }
    } catch (e) {
      print('Error applying user location marker: $e');
    }
  }

  Future<void> _addDirectionArrow() async {
    try {
      // Use the GeoPoint stored in `pos.position`
      GeoPoint currentPosition = pos.position;

      // Add the direction arrow marker
      await _controller.addMarker(
        currentPosition,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.double_arrow,
            color: Colors.blue,
            size: 48,
          ),
        ),
      );
    } catch (e) {
      print('Error adding direction arrow marker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: OSMFlutter(
          controller: _controller,
          osmOption: OSMOption(
            userTrackingOption: const UserTrackingOption(
              enableTracking: true,
              unFollowUser: false,
            ),
            zoomOption: const ZoomOption(
              initZoom: 8,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
            userLocationMarker: UserLocationMaker(
              personMarker: const MarkerIcon(
                icon: Icon(
                  Icons.location_history_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              directionArrowMarker: const MarkerIcon(
                icon: Icon(
                  Icons.double_arrow,
                  color: Colors.blue,
                  size: 48,
                ),
              ),
            ),
            roadConfiguration: const RoadOption(
              roadColor: Colors.yellowAccent,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Save/Search',
        onPressed: () async {
          try {
            // Get current location and update pos.position
            GeoPoint location = await _controller.myLocation();
            await pos.checkRouting(Future.value(location));

            setState(() {
              _isNavigating = pos.isNavigating();
            });

            // Apply markers with updated navigation state
            await _applyUserLocationMarker();
          } catch (e) {
            print('Error handling location: $e');
          }
        },
        child: const Icon(Icons.assistant_navigation),
      ),
    );
  }
}
