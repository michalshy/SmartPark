import 'dart:async'; // For Timer
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_core/firebase_core.dart';
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

  Parking(GeoPoint pos, int availability) {
    position = pos;
    maxSlots = availability; // Ustawiamy maksymalną liczbę miejsc na podstawie danych
    availableSlots = availability; // Początkowo dostępne miejsca są równe maksymalnym
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
  Position pos = Position(0, 0);
  bool _dirArrow = true;
  bool _isNavigating = false;
  GeoPoint? currPos;
  List<Parking> parkings = [];
  late Timer _updateTimer;
  var db;
  var docRef;
  List<GeoPoint> _currentMarkers = [];


  final _controller = MapController.withUserPosition(
    trackUserLocation: const UserTrackingOption(
      enableTracking: true,
      unFollowUser: false,
    ),
  );

@override
void initState() {
  super.initState();
  _initialize();
}

Future<void> _initialize() async {
  await _initializeController();
  _setupLocationListener();
  await _initParkings();
  _startUpdateTimer();
}

  Future<void> _initializeController() async {
    try {
      await _controller.startLocationUpdating();
    } catch (e) {
      print('Error initializing MapController: $e');
    }
  }

  Parking? _getTappedParking(GeoPoint tappedPoint, {double threshold = 0.0005}) {
  for (Parking parking in parkings) {
    if (_isPointNear(tappedPoint, parking.getPosition(), threshold: threshold)) {
      return parking;
    }
  }
  return null;
}

  bool _isPointNear(GeoPoint point, GeoPoint marker, {double threshold = 0.0005}) {
    return (point.latitude - marker.latitude).abs() < threshold &&
          (point.longitude - marker.longitude).abs() < threshold;
  }

  void _setupLocationListener() {
    _controller.listenerMapLongTapping.addListener(() {
      // Reapply markers when map updates
      _applyUserLocationMarker(GeoPoint(latitude: 0, longitude: 0));
    });

    _controller.listenerMapSingleTapping.addListener(() async {
    GeoPoint? tappedPoint = _controller.listenerMapSingleTapping.value;

    if (tappedPoint != null) {
      print('pawel');
      Parking? tappedParking = _getTappedParking(tappedPoint);
      if (tappedParking != null) {
        print('olek');
        _showParkingPopup(tappedParking);
      }
    }
  });
}


Future<void> _initParkings() async {
  db = fs.FirebaseFirestore.instance;

  docRef = db.collection("parkings").doc("myparkings");

  // Nasłuchiwanie zmian w dokumencie
  docRef.snapshots().listen((docSnapshot) {
    if (docSnapshot.exists) {
      // Pobieramy dane jako mapę
      var data = docSnapshot.data() as Map<String, dynamic>;

      // Zakładamy, że "parkings" to lista map
      List<dynamic> parkingData = data['parkings'] ?? [];
      parkings.clear(); // Czyścimy istniejącą listę parkingów
      for (var parking in parkingData) {
        if (parking is Map<String, dynamic>) {
          // Pobieramy lokalizację i dostępność
          var location = parking['location'] as fs.GeoPoint;
          int availability = parking['availability'] ?? 0;

          // Dodajemy parking na podstawie danych
          parkings.add(Parking(
            GeoPoint(latitude: location.latitude, longitude: location.longitude),
            availability, // Ustawiamy liczbę maksymalnych miejsc parkingowych
          ));
        }
      }
      // Aktualizujemy widok parkingów na mapie
      _updateParkings();
    }
  }, onError: (e) {
    print("Error listening to document changes: $e");
  });
}



  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateParkings();
    });
  }

Future<void> _updateParkings() async {
  try {
    // Usuwamy istniejące markery
    for (GeoPoint marker in _currentMarkers) {
      await _controller.removeMarker(marker);
    }
    _currentMarkers.clear();

    // Dodajemy nowe markery
    for (Parking parking in parkings) {
      await _controller.addMarker(
        parking.getPosition(),
        markerIcon: MarkerIcon(
          icon: Icon(
            Icons.local_parking,
            color: parking.getAvailableSlots() > 0 ? Colors.green : Colors.red,
            size: 48,
          ),
        ),
      );
      // Dodajemy marker do listy
      _currentMarkers.add(parking.getPosition());
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
    // Czyścimy poprzednie drogi
    await _controller.clearAllRoads();

    // Rysujemy trasę na mapie
    await _controller.drawRoad(
      start,
      end,
      roadOption: const RoadOption(
        roadColor: Color.fromARGB(255, 238, 5, 165),
        roadWidth: 8.0,
      ),
    );

    print("Navigation started from $start to $end");
  } catch (e) {
    print("Error drawing road: $e");
  }
}

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  Parking findClosestParking()
  {
    double minX = 1000;
    double minY = 1000;
    double tempX, tempY;
    double lat = 0, long = 0;
    Parking closestParking = Parking(GeoPoint(latitude: lat,longitude: long), 2);
    for (Parking parking in parkings) {
      tempX = (pos.position.latitude - parking.position!.latitude).abs();
      tempY = (pos.position.longitude - parking.position!.longitude).abs();
      if(tempX < minX && tempY < minY && parking.availableSlots! > 0)
      {
        minX = tempX;
        minY = tempY;
        closestParking = parking;
      }
    }

    return closestParking;
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

          // Usuń poprzedni marker przed dodaniem nowego
          await _applyUserLocationMarker(location);

          if (_dirArrow) {
            await _addDirectionArrow(pos.position);
            _dirArrow = false;
          }
        } catch (e) {
          print('Error handling location: $e');
        }
      },
      child: const Icon(Icons.assistant_navigation),
    ),
          const SizedBox(height: 16),
          FloatingActionButton(
            tooltip: 'Navigate to Free Parking Slot',
            onPressed: () async {
              Parking closestParking = findClosestParking();
              if (_isNavigating) {
                await navigateTo(pos.position, closestParking.position!);
                _showParkingPopup(closestParking);
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Error occurred"),
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
            child: const Icon(Icons.local_parking_sharp),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            tooltip: 'Navigate to Destination',
            onPressed: () async {
              if (_isNavigating) { 
                await navigateTo(currPos!, pos.position);
              }
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<fs.DocumentSnapshot> getData() async {
    await Firebase.initializeApp();
    return await fs.FirebaseFirestore.instance
        .collection("parkings")
        .doc("myparkings")
        .get();
  }
}
