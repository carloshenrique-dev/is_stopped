import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MovementDetector {
  List<Position> positions = [];
  List<UserAccelerometerEvent> accEvents = [];
  double thresholdSpeed = 5; // km/h (reduzi o limite de velocidade)
  double thresholdAcc = 1.0; // m/s^2 (aumentei o limite de aceleração)
  int numMeasurements = 5;

  Future<ReturnClass> isMoving(Position position) async {
    //AccelerometerEvent accEvent = await accelerometerEvents.first;
    UserAccelerometerEvent userAccelerometerEvent = await userAccelerometerEvents.first;
    print(userAccelerometerEvent);

    positions.add(position);
    accEvents.add(userAccelerometerEvent);
    if (positions.length > numMeasurements) {
      positions.removeAt(0);
      accEvents.removeAt(0);
    }

    if (positions.length < numMeasurements) {
      return ReturnClass(avgAccAccelerometer: 0.0, avgSpeed: 0.0, avgAccGPS: 0.0, isStopped: false);
    }

    double avgSpeed = positions.map((p) => p.speed).reduce((a, b) => a + b) / numMeasurements * 3.6; // m/s para km/h

    double avgAccGPS = (positions.last.speed - positions[3].speed) /
        positions.last.timestamp!.difference(positions[3].timestamp!).inSeconds; // m/s^2 para km/h^2

    // Calcular a aceleração média usando os dados do acelerômetro
    double avgAccAccelerometer =
        accEvents.map((a) => sqrt((a.x * a.x + a.y * a.y + a.z * a.z))).reduce((a, b) => a + b) / numMeasurements;

    // Comparar os valores de velocidade e aceleração com os limiares
    if (avgSpeed > thresholdSpeed && avgAccGPS > thresholdAcc && avgAccAccelerometer > thresholdAcc) {
      // || avgAccAccelerometer > thresholdAcc) {
      return ReturnClass(
          avgAccAccelerometer: avgAccAccelerometer, avgSpeed: avgSpeed, avgAccGPS: avgAccGPS, isStopped: false);
    } else {
      return ReturnClass(
          avgAccAccelerometer: avgAccAccelerometer, avgSpeed: avgSpeed, avgAccGPS: avgAccGPS, isStopped: true);
    }
  }
}

class ReturnClass {
  final double avgSpeed;
  final double avgAccAccelerometer;
  final double avgAccGPS;
  final bool isStopped;

  ReturnClass({
    required this.avgSpeed,
    required this.avgAccAccelerometer,
    required this.isStopped,
    required this.avgAccGPS,
  });

  @override
  String toString() {
    return 'ReturnClass(avgSpeed: $avgSpeed, avgAccAccelerometer: $avgAccAccelerometer, avgAccGPS: $avgAccGPS, isStopped: $isStopped)';
  }
}
