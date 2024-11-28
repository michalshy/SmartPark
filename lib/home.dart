import 'package:flutter/material.dart';
import 'position.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

// ignore: must_be_immutable
class Home extends StatelessWidget {
  Home({super.key});

  Position pos = Position(0.0, 0.0);
  final _controller = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: false,
  ));

  void wait(controller) async {
    await controller.startLocationUpdating();
  }

  @override
  Widget build(BuildContext context) {
    wait(_controller);

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
        onPressed: () => pos.checkRouting(_controller.myLocation()),
        child: const Icon(Icons.assistant_navigation),
      ),
    );
  }
}
