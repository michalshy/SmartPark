class Position {
  Position(double lat, double long) {
    position = (lat, long);
  }

  (double, double) position = (0, 0);

  void setPosition(double lat, double long) {
    position = (lat, long);
  }
}
