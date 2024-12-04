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
      _applyUserLocationMarker(GeoPoint(latitude: 0.0, longitude: 0.0));
    });
  }

  Future<void> _applyUserLocationMarker(GeoPoint p) async {
    try {
      await _controller.addMarker(
        p, 
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_history_rounded,
            color: Colors.red,
            size: 48,
          ),
        ),
      );
    } catch (e) {
      print('Error applying user location marker: $e');
    }
  }

  Future<void> _addDirectionArrow(GeoPoint p) async {
    try {

      await _controller.addMarker(
        p,
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

    Future<void> navigateTo(GeoPoint start ,GeoPoint end) async {
    try {

      await _controller.drawRoad(
        start,
        end,
        roadOption: const RoadOption(
          roadColor: Color.fromARGB(255, 238, 5, 165),
          roadWidth: 14.0,
        ),
      );

      print("Navigation started from $start to $end");
    } catch (e) {
      print("Error during navigation: $e");
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
              roadColor: Color.fromARGB(255, 238, 5, 165),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Save/Search',
        onPressed: () async {
          try {
            GeoPoint location = await _controller.myLocation();
            await pos.checkRouting(Future.value(location));
            print('Current position: ${location.latitude}, ${location.longitude}');
            print('Pos position: ${pos.position}');
            setState(() {
              _isNavigating = pos.isNavigating();
            });
            await _controller.removeMarker(pos.position);
            await _applyUserLocationMarker(location);
            if(_isNavigating)
             {
              await _addDirectionArrow(pos.position);
              await navigateTo(location, pos.position);
              }
          } catch (e) {
            print('Error handling location: $e');
          }
        },
        child: const Icon(Icons.assistant_navigation),
      ),
    );
  }
}
