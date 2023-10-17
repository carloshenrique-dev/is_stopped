import 'dart:async';

import 'package:flutter/material.dart';
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
  final List<double> _accel = <double>[];
  List<double> _gyroscopeData = [0, 0, 0];
  CompassEvent? _compassData;
  double _speed = 0.0;
  bool _movement = true;
  final double _simulatedSpeed = 0.0; // Initialize to 0
  final double _simulatedDirection = 0.0; // Initialize to 0
  late StreamSubscription<GyroscopeEvent> gyroSub;
  @override
  void initState() {
    Geolocator.requestPermission();
    _determinePosition();
    super.initState();
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
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
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
            _movement
                ? Container(
                    height: 500,
                    width: 500,
                    color: Colors.red,
                  )
                : const SizedBox.shrink(),
            ElevatedButton(
                onPressed: () {
                  gyroSub.cancel();

                  // Simulate a change in speed and direction
                  setState(() {
                    _speed = 4.0 / 3.6; // Simulate 4 km/h (convert to m/s)
                    _gyroscopeData = [
                      0.0,
                      0.0,
                      10.0
                    ]; // Simulate a change in z-axis rotation (gyroscope data)
                  });
                  // Call the function to check if the tractor is stopped
                  checkTractorStopped();
                },
                child: const Text('Simulation'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
            _gyroscopeData = [event.x, event.y, event.z];
            // Implement your orientation update logic here
            // Use gyroscope data for more accurate orientation estimation
            checkTractorStopped();
          });

          Geolocator.getPositionStream()
              .listen((final Position currentLocation) {
            _speed = currentLocation.speed;
            setState(() {});
            checkTractorStopped();
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void checkTractorStopped() {
    // Implement your sensor fusion and filtering logic here
    // Use data from _gyroscopeData, _gpsSpeed, and any other relevant sensors
    // Determine if the tractor is stopped or in motion
    double gyroscopeHeading =
        _gyroscopeData[2]; // Assuming z-axis rotation represents heading change
    double directionThreshold = 10.0; // degrees (you can adjust this value)
    double accelerometerThreshold = 0.2; // You can adjust this value

    // Check if the change in direction is minimal
    if (gyroscopeHeading.abs() < directionThreshold) {
      // Check if accelerometer data indicates minimal movement
      if (_gyroscopeData
          .every((value) => value.abs() < accelerometerThreshold)) {
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
