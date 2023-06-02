import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

final db = FirebaseFirestore.instance;
final driverLocationRef = db.collection('driver_locations').doc('driver1');

// Update the driver location in the database
updateDriverLocation(Position position) {
  GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);
  driverLocationRef
      .set({'location': geoPoint, 'timestamp': FieldValue.serverTimestamp()});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Stop Driver',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position _currentPosition;
  bool _loading = true;
  bool serviceEnabled = false;
  LocationPermission permission = LocationPermission.denied;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _positionStream?.cancel();
  }

  void _getCurrentLocation() async {
    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show an error dialog.
        return Future.error('Location services are disabled.');
      }

      // Request permission to use location.
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, show error dialog.
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('Location permissions denied'),
              content: Text(
                  'Bus Stop Driver cannot function without access to your location.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
                TextButton(
                  onPressed: () => Geolocator.openAppSettings(),
                  child: Text('Settings'),
                ),
              ],
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Location permissions permanently denied'),
            content: Text(
                'Bus Stop Driver cannot function without access to your location. '
                'Please grant location permissions from the app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: Text('Settings'),
              ),
            ],
          ),
        );
        return;
      }

      // Get the current position.
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _loading = false;
      });

      // Listen for location changes and update
      _positionStream =
          Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentPosition = position;
        });
        updateDriverLocation(position);
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Stop Driver'),
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Text(
                'Latitude: ${_currentPosition.latitude}, Longitude: ${_currentPosition.longitude}'),
      ),
    );
  }
}
