import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'navigation.dart';

enum PosState { waiting, saved }

class Position {
  Position(double lat, double long) {
    position = GeoPoint(latitude: lat, longitude: long);
  }

  GeoPoint position = GeoPoint(latitude: 0, longitude: 0);
  PosState state = PosState.waiting;
  Navigation nav = Navigation();

  bool isNavigating() {
    return state == PosState.saved;
  }

  Future<void> checkRouting(Future<GeoPoint> geo) async {
    try {
      GeoPoint resolvedGeo = await geo;
      switch (state) {
        case PosState.waiting:
          position = resolvedGeo;
          state = PosState.saved;
          print('Saved position: ${position.latitude}, ${position.longitude}');
          break;
        case PosState.saved:
          nav.Navigate(position);
          print('Navigating to position: ${position.latitude}, ${position.longitude}');
          break;
      }
    } catch (e) {
      print('Error resolving GeoPoint: $e');
    }
  }
}