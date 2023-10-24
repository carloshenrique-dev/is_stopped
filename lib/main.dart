import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart' as act;
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

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

  StreamSubscription<act.ActivityEvent>? activityStreamSubscription;
  final List<Activity> _events = [];
  act.ActivityRecognition activityRecognition = act.ActivityRecognition();
  final FlutterActivityRecognition activityRecognitionI = FlutterActivityRecognition.instance;

  @override
  void initState() {
    super.initState();
    _init();
    _events.add(Activity.unknown);
  }

  @override
  void dispose() {
    activityStreamSubscription?.cancel();
    super.dispose();
  }

  void _init() async {
    // Check if the user has granted permission. If not, request permission.
    PermissionRequestResult reqResult;
    reqResult = await activityRecognitionI.checkPermission();
    if (reqResult == PermissionRequestResult.PERMANENTLY_DENIED) {
      log('Permission is permanently denied.');
      //return false;6
    } else if (reqResult == PermissionRequestResult.DENIED) {
      reqResult = await activityRecognitionI.requestPermission();
      if (reqResult != PermissionRequestResult.GRANTED) {
        log('Permission is denied.');
        //return false;
      }
    }
    _startTracking();

    //return true;
  }

  void _startTracking() {
    // Subscribe to the activity stream.or
    final activityStreamSubscription = activityRecognitionI.activityStream.handleError(onError).listen(onData);
    //activityStreamSubscription =
    //    activityRecognition.activityStream(runForegroundService: true).listen(onData, onError: onError);
  }

  void onData(Activity activityEvent) {
    print(activityEvent);
    setState(() {
      _events.add(activityEvent);
    });
  }

  void onError(Object error) {
    print('ERROR - $error');
  }

  Future<geo.Position> _determinePosition() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await geo.Geolocator.getCurrentPosition();
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
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                reverse: true,
                itemBuilder: (_, int idx) {
                  final activity = _events[idx];
                  return ListTile(
                    leading: _activityIcon(activity.type),
                    title: Text('${activity.type.toString().split('.').last} (${activity.confidence}%)'),
                    //trailing: Text(activity.timeStamp.toString().split(' ').last.split('.').first),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _determinePosition();

          const geo.LocationSettings locationSettings = geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 100,
          );

          geo.Geolocator.getPositionStream(locationSettings: locationSettings).listen((geo.Position? position) async {
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

  Icon _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.IN_VEHICLE:
        return const Icon(Icons.car_rental);
      case ActivityType.ON_BICYCLE:
        return const Icon(Icons.pedal_bike);
      case ActivityType.WALKING:
        return const Icon(Icons.directions_walk);
      case ActivityType.RUNNING:
        return const Icon(Icons.run_circle);
      case ActivityType.STILL:
        return const Icon(Icons.cancel_outlined);
      case ActivityType.UNKNOWN:
        return const Icon(Icons.device_unknown);
      default:
        return const Icon(Icons.device_unknown);
    }
  }
}
