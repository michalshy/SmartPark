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

  void checkRouting(Future<GeoPoint> geo) {
    switch (state) {
      case PosState.waiting:
        position = geo as GeoPoint;
      case PosState.saved:
        nav.Navigate(position);
    }
  }
}
