import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'position.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

// ignore: must_be_immutable
class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class Parking {
  GeoPoint? position;
  int? maxSlots;
  int? availableSlots;

  Parking(GeoPoint pos, int max) {
    position = pos;
    maxSlots = max;
    availableSlots = max;
  }

  void updateAvailableSlots(int slots) {
    availableSlots = slots;
  }

  int getAvailableSlots() {
    return availableSlots!;
  }

  GeoPoint getPosition() {
    return position!;
  }
}

class _HomeState extends State<Home> {
  Position pos = Position(0.0, 0.0);
  bool _isNavigating = false;
  GeoPoint? currPos;
  List<Parking> parkings = [];
  late Timer _updateTimer;

  final _controller = MapController.withUserPosition(
    trackUserLocation: const UserTrackingOption(
      enableTracking: true,
      unFollowUser: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupLocationListener();
    _initParkings();
    _startUpdateTimer();
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

  void _initParkings() // TODO: GET LIST OF PARKINGS FROM DATABASE
  {
    Parking p = Parking(GeoPoint(latitude: 37.021998333333335, longitude: -121.084), 2);
    parkings.add(p);
    _updateParkings();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateParkings();
    });
  }

  Future<void> _updateParkings() async {
    try {
      for (Parking parking in parkings) {
        int newAvailableSlots = 2; // TODO: Fetch from database
        parking.updateAvailableSlots(newAvailableSlots);

        // Add marker for the parking with a tap event to show popup
        await _controller.addMarker(
          parking.getPosition(),
          markerIcon: MarkerIcon(
            iconWidget: GestureDetector(
              onTapUp: (_) {
                print("Parking tapped!"); // For debugging
                _showParkingPopup(parking);
              },
              child: Icon(
                Icons.local_parking,
                color: Colors.green,
                size: 48,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating parkings: $e');
    }
  }

  void _showParkingPopup(Parking parking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Parking Information"),
          content: Text(
            "Available Slots: ${parking.getAvailableSlots()} / ${parking.maxSlots}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
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

  Future<void> navigateTo(GeoPoint start, GeoPoint end) async {
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
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
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
              roadColor: Color.fromARGB(255, 238, 5, 114),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            tooltip: 'Save/Search',
            onPressed: () async {
              try {
                GeoPoint location = await _controller.myLocation();
                await pos.checkRouting(Future.value(location));
                currPos = location;
                print('Current position: ${location.latitude}, ${location.longitude}');
                print('Pos position: ${pos.position}');
                setState(() {
                  _isNavigating = pos.isNavigating();
                });
                await _controller.removeMarker(pos.position);
                await _applyUserLocationMarker(location);
                if (_isNavigating) {
                  await _addDirectionArrow(pos.position);
                }
              } catch (e) {
                print('Error handling location: $e');
              }
            },
            child: const Icon(Icons.assistant_navigation),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            tooltip: 'Navigate to Destination',
            onPressed: () async {
              if (_isNavigating) await navigateTo(currPos!, pos.position);
              else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("No Location Saved"),
                      content: const Text("You need to save a location before navigating."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: const Icon(Icons.directions),
          ),
        ],
      ),
    );
  }
}
