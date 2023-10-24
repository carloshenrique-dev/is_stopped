// ignore_for_file: public_member_api_docs, sort_constructors_first
// with filter
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MovementDetector {
  List<Position> positions = [];
  List<AccelerometerEvent> accEvents = [];
  double thresholdSpeed = 2.0; // km/h
  double thresholdAcc = 0.5; // m/s^2
  int numMeasurements = 5;

  Future<ReturnClass> isMoving(Position position) async {
    /*Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      forceAndroidLocationManager: true,
      //timeLimit: const Duration(seconds: 5),
    );*/
    AccelerometerEvent accEvent = await accelerometerEvents.first;

    positions.add(position);
    accEvents.add(accEvent);
    if (positions.length > numMeasurements) {
      positions.removeAt(0);
      accEvents.removeAt(0);
    }

    if (positions.length < numMeasurements) {
      return ReturnClass(avgAccAccelerometer: 0.0, avgAccGPS: 0.0, avgSpeed: 0.0, isStopped: false);
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
      return ReturnClass(
          avgAccAccelerometer: avgAccAccelerometer, avgAccGPS: avgAccGPS, avgSpeed: avgSpeed, isStopped: true);
    } else {
      return ReturnClass(
          avgAccAccelerometer: avgAccAccelerometer, avgAccGPS: avgAccGPS, avgSpeed: avgSpeed, isStopped: false);
    }
  }
}

class ReturnClass {
  final double avgSpeed;
  final double avgAccGPS;
  final double avgAccAccelerometer;
  final bool isStopped;

  ReturnClass({
    required this.avgSpeed,
    required this.avgAccGPS,
    required this.avgAccAccelerometer,
    required this.isStopped,
  });

  @override
  String toString() {
    return 'ReturnClass(avgSpeed: $avgSpeed, avgAccGPS: $avgAccGPS, avgAccAccelerometer: $avgAccAccelerometer, isStopped: $isStopped)';
  }
}
