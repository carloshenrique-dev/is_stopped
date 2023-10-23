import 'package:geolocator/geolocator.dart';

class SimpleMovementDetector {
  List<Position> positions = [];
  double thresholdSpeed = 2.0; // km/h
  double thresholdAcc = 0.5; // m/s^2
  int numMeasurements = 5;

  Future<bool> isMoving() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    positions.add(position);
    if (positions.length > numMeasurements) {
      positions.removeAt(0);
    }

    if (positions.length < numMeasurements) {
      return false;
    }

    double avgSpeed = positions.map((p) => p.speed).reduce((a, b) => a + b) / numMeasurements * 3.6; // m/s to km/h
    double avgAcc = positions.map((p) => p.speed).reduce((a, b) => a - b) /
        positions.first.timestamp!.difference(positions.last.timestamp!).inSeconds *
        3.6; // m/s^2 to km/h^2

    if (avgSpeed > thresholdSpeed && avgAcc > thresholdAcc) {
      return true;
    } else {
      return false;
    }
  }
}
