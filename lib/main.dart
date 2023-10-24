import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'models/movement_detector.dart';

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
  bool isInMovement = false;
  List<ReturnClass> returnList = [];

  @override
  void initState() {
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
            isInMovement ? const Text('IS IN MOVEMENT') : const Text('IS NOT IN MOVEMENT'),
            Expanded(
              child: ListView.builder(
                itemCount: returnList.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Text('AvgAccel ${returnList[index].avgAccAccelerometer}'),
                      Text('AvgGPS ${returnList[index].avgAccGPS}'),
                      Text('AvgSpeed ${returnList[index].avgSpeed}'),
                      Text('isStopped ${returnList[index].isStopped}'),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          const LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          );

          Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) async {
            print(
              position == null
                  ? 'Unknown'
                  : '${position.latitude.toString()}, ${position.longitude.toString()}, ${position.accuracy.toString()}, ${position.speed.toString()}',
            );
            if (position != null) {
              final result = await MovementDetector().isMoving(position);
              returnList.add(result);
              print(result);
              if (result.isStopped) {
                setState(() {
                  isInMovement = true;
                });
              } else {
                setState(() {
                  isInMovement = false;
                });
              }
            }
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
