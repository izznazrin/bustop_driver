import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class BusStatus extends StatefulWidget {
  const BusStatus({Key? key}) : super(key: key);

  @override
  State<BusStatus> createState() => _BusStatusState();
}

class _BusStatusState extends State<BusStatus> {
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
    fetchOptionsFromFirebase();
  }

  @override
  void dispose() {
    stopUpdatingLocation();
    super.dispose();
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

  bool isButtonPressed = false;

  String? selectedOption = 'Choose Bus Plate Number';
  List<String> options = ['Choose Bus Plate Number'];

  void fetchOptionsFromFirebase() {
    FirebaseFirestore.instance
        .collection('Bus')
        .get()
        .then((QuerySnapshot snapshot) {
      List<String> fetchedOptions = ['Choose Bus Plate Number'];
      print('Number of documents retrieved: ${snapshot.docs.length}');
      snapshot.docs.forEach((DocumentSnapshot doc) {
        String? plateNumber = (doc.data()
            as Map<String, dynamic>?)?['bus_platenumber'] as String?;
        print('Plate number: $plateNumber');
        if (plateNumber != null) {
          fetchedOptions.add(plateNumber);
        }
      });

      setState(() {
        options = fetchedOptions;
      });
    }).catchError((error) {
      // Handle the error
      print('Error retrieving options from Firebase: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDestinationChosen = selectedOption != 'Choose Bus Plate Number';
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          Material(
            elevation: 4,
            child: Container(
              height: 50,
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 16),
                    child: Text(
                      'GPS Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: driverLocationRef?.snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasData) {
                            GeoPoint? driverLocation = (snapshot.data!.data()
                                    as Map<String, dynamic>?)?[
                                'driver_location'] as GeoPoint?;
                            if (driverLocation != null) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      '${driverLocation.latitude},${driverLocation.longitude}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              'No Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(20),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 40,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: IgnorePointer(
                              ignoring: isButtonPressed,
                              child: Opacity(
                                opacity: isButtonPressed ? 0.5 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedOption,
                                    onChanged: isButtonPressed
                                        ? null // Disable the dropdown button if the button is pressed
                                        : (String? newValue) {
                                            setState(
                                              () {
                                                selectedOption = newValue;
                                                isDestinationChosen =
                                                    selectedOption !=
                                                        'Choose Bus Plate Number';
                                              },
                                            );
                                          },
                                    underline:
                                        Container(), // Remove the default underline
                                    items:
                                        options.map<DropdownMenuItem<String>>(
                                      (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              value,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isDestinationChosen)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isButtonPressed = true;
                });
                startUpdatingLocation();
              },
              child: Text('Start'),
            ),
          if (isDestinationChosen)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isButtonPressed = false;
                });
                stopUpdatingLocation();
              },
              child: Text('Stop'),
            ),
        ],
      ),
    );
  }
}
