// with filter
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MovementDetector {
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

    // Apply moving average filter to accelerometer data
    double avgAccAccelerometer = accEvents.map((a) => a.x + a.y + a.z).reduce((a, b) => a + b) / numMeasurements;

    print(avgSpeed);
    print(avgAccGPS);
    print(avgAccAccelerometer);

    //comparar se em condicoes normais as medidas de acelerometro e speed vindo do gps estao parecidos
    if ((avgSpeed > thresholdSpeed && avgAccGPS > thresholdAcc) || avgAccAccelerometer > thresholdAcc) {
      return true;
    } else {
      return false;
    }
  }
}
