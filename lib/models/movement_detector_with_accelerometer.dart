//second version with accelerometer but without filter

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MovementDetectorWithAccelerometer {
  List<Position> positions = [];
  List<AccelerometerEvent> accEvents = [];
  double thresholdSpeed = 2.0; // km/h
  double thresholdAcc = 0.5; // m/s^2
  int numMeasurements = 5;

  Future<bool> isMoving() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    AccelerometerEvent accEvent = await accelerometerEvents.first;

    positions.add(position);
    accEvents.add(accEvent);
    if (positions.length > numMeasurements) {
      positions.removeAt(0);
      accEvents.removeAt(0);
    }

    if (positions.length < numMeasurements) {
      return false;
    }

    double avgSpeed = positions.map((p) => p.speed).reduce((a, b) => a + b) / numMeasurements * 3.6; // m/s to km/h
    double avgAccGPS = positions.map((p) => p.speed).reduce((a, b) => a - b) /
        positions.first.timestamp!.difference(positions.last.timestamp!).inSeconds *
        3.6; // m/s^2 to km/h^2

    double avgAccAccelerometer = accEvents.map((a) => a.x + a.y + a.z).reduce((a, b) => a + b) / numMeasurements;

    if ((avgSpeed > thresholdSpeed && avgAccGPS > thresholdAcc) || avgAccAccelerometer > thresholdAcc) {
      return true;
    } else {
      return false;
    }
  }
}
