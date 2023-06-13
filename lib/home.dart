import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseFirestore? db;
  DocumentReference? driverLocationRef;
  StreamSubscription<Position>? locationSubscription;
  bool isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((value) {
      db = FirebaseFirestore.instance;
      driverLocationRef = db!.collection('Driver').doc('driver1');
    });
  }

  void startUpdatingLocation() async {
    // Check if location updates are already in progress
    if (isUpdatingLocation) return;

    // Check location service status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Location services disabled'),
          content: Text('Please enable location services to proceed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Location permission denied'),
            content: Text('Please grant location permission to proceed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Start location updates
    locationSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      // Update driver location in Firestore
      updateDriverLocation(position);
    });

    setState(() {
      isUpdatingLocation = true;
    });
  }

  void stopUpdatingLocation() {
    // Stop location updates
    locationSubscription?.cancel();
    locationSubscription = null;

    setState(() {
      isUpdatingLocation = false;
    });
  }

  void updateDriverLocation(Position position) {
    GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);
    driverLocationRef?.set({
      'driver_location': geoPoint,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Status'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: startUpdatingLocation,
              child: Text('Start'),
            ),
            ElevatedButton(
              onPressed: stopUpdatingLocation,
              child: Text('Stop'),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: driverLocationRef?.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasData) {
                  GeoPoint? driverLocation = (snapshot.data!.data()
                          as Map<String, dynamic>?)?['driver_location']
                      as GeoPoint?;
                  if (driverLocation != null) {
                    return Column(
                      children: [
                        Text('Latitude: ${driverLocation.latitude}'),
                        Text('Longitude: ${driverLocation.longitude}'),
                      ],
                    );
                  }
                }
                return Text('No location available');
              },
            ),
          ],
        ),
      ),
    );
  }
}
