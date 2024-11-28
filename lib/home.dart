import 'package:flutter/material.dart';
import 'position.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class Home extends StatelessWidget {
  Home({super.key});

  Position pos = Position(0.0, 0.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'Nav',
          onPressed: null,
        ),
        title: const Text('FYC'),
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      ),
      body: Center(
          child: OSMFlutter(
              controller: MapController(
                initPosition:
                    GeoPoint(latitude: 47.4358055, longitude: 8.4737324),
                areaLimit: const BoundingBox(
                  east: 10.4922941,
                  north: 47.8084648,
                  south: 45.817995,
                  west: 5.9559113,
                ),
              ),
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
                      size: 48,
                    ),
                  ),
                ),
                roadConfiguration: const RoadOption(
                  roadColor: Colors.yellowAccent,
                ),
              ))),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Save/Search',
        onPressed: () => pos.setPosition(100.0, 100.0),
        child: const Icon(Icons.assistant_navigation),
      ),
    );
  }
}
