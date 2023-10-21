import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final activityRecognition = FlutterActivityRecognition.instance;
  final List<double> _accel = <double>[];
  final List<double> _gyroscopeData = [0, 0, 0];
  CompassEvent? _compassData;
  final double _speed = 0.0;
  bool _movement = true;
  final double _simulatedSpeed = 0.0; // Initialize to 0
  final double _simulatedDirection = 0.0; // Initialize to 0
  late StreamSubscription<GyroscopeEvent> gyroSub;
  @override
  void initState() {
    Geolocator.requestPermission();
    _determinePosition();
    isPermissionGrants();
    super.initState();
  }

  Future<bool> isPermissionGrants() async {
    // Check if the user has granted permission. If not, request permission.
    PermissionRequestResult reqResult;
    reqResult = await activityRecognition.checkPermission();
    if (reqResult == PermissionRequestResult.PERMANENTLY_DENIED) {
      log('Permission is permanently denied.');
      return false;
    } else if (reqResult == PermissionRequestResult.DENIED) {
      reqResult = await activityRecognition.requestPermission();
      if (reqResult != PermissionRequestResult.GRANTED) {
        log('Permission is denied.');
        return false;
      }
    }

    return true;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              stream: activityRecognition.activityStream,
              builder: (context, activity) {
                return Text(activity.data?.type.name ?? 'NO ACTIVITY');
              },
            ),
            /*_movement
                ? Container(
                    height: 500,
                    width: 500,
                    color: Colors.red,
                  )
                : const SizedBox.shrink(),*/
            ElevatedButton(
                onPressed: () {
                  // Subscribe to the activity stream.
                  final activityStreamSubscription = activityRecognition.activityStream.listen((event) {
                    setState(() {});
                  });
                  /*gyroSub.cancel();

                  // Simulate a change in speed and direction
                  setState(() {
                    _speed = 4.0 / 3.6; // Simulate 4 km/h (convert to m/s)
                    _gyroscopeData = [0.0, 0.0, 10.0]; // Simulate a change in z-axis rotation (gyroscope data)
                  });
                  // Call the function to check if the tractor is stopped
                  checkTractorStopped();*/
                },
                child: const Text('Simulation'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /*gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
            _gyroscopeData = [event.x, event.y, event.z];
            //print(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
            // Implement your orientation update logic here
            // Use gyroscope data for more accurate orientation estimation
            //checkTractorStopped();
          });

          accelerometerEvents.listen((event) {
            _accel = [event.x, event.y, event.z];
          });*/

          Geolocator.getPositionStream().listen((final Position currentLocation) {
            _accel.add(currentLocation.speed);
            print(currentLocation.speed);
            setState(() {});
            //checkTractorStopped();
            /*isStopped(
              currentLocation.speed,
              math.sqrt(
                _gyroscopeData[0] * _gyroscopeData[0] +
                    _gyroscopeData[1] * _gyroscopeData[1] +
                    _gyroscopeData[2] * _gyroscopeData[2],
              ),
            );*/
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  double calcularMediaUltimos5(List<double> velocidades) {
    // Verifique se há pelo menos 5 velocidades na lista
    if (velocidades.length < 5) {
      throw ArgumentError("A lista de velocidades deve conter pelo menos 5 elementos.");
    }

    // Obtenha os últimos 5 elementos da lista
    List<double> ultimas5Velocidades = velocidades.sublist(velocidades.length - 5);

    // Calcule a média
    double soma = ultimas5Velocidades.reduce((a, b) => a + b);
    double media = soma / 5.0;

    return media;
  }

  bool isStopped(double speed, double acceleration) {
    print('is Stopped');
    if (_accel.length > 5) calcularMediaUltimos5(_accel);
    return speed < 0.5 && acceleration < 0.1;
  }

  void checkTractorStopped() {
    // Implement your sensor fusion and filtering logic here
    // Use data from _gyroscopeData, _gpsSpeed, and any other relevant sensors
    // Determine if the tractor is stopped or in motion
    double gyroscopeHeading = _gyroscopeData[2]; // Assuming z-axis rotation represents heading change
    double directionThreshold = 10.0; // degrees (you can adjust this value)
    double accelerometerThreshold = 0.2; // You can adjust this value

    // Check if the change in direction is minimal
    if (gyroscopeHeading.abs() < directionThreshold) {
      // Check if accelerometer data indicates minimal movement
      if (_gyroscopeData.every((value) => value.abs() < accelerometerThreshold)) {
        // Check if GPS speed is very low (considering the tractor's maximum speed)
        if (_speed < 5.0 / 3.6) {
          // The tractor is considered stopped
          setState(() {
            _movement = false;
          });
          print("Tractor is stopped");
        }
      }
    } else {
      // If the direction change is above the threshold, the tractor is in motion
      setState(() {
        _movement = true;
      });
    }
  }
}
