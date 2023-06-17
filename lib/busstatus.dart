import 'package:bustop_driver/passenger.dart';
import 'package:bustop_driver/profile.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

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
  final user = FirebaseAuth.instance.currentUser!;

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
    driverLocationRef?.update({
      'driver_location': geoPoint,
      //'timestamp': FieldValue.serverTimestamp()
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
      snapshot.docs.forEach((DocumentSnapshot doc) {
        String? plateNumber = (doc.data()
            as Map<String, dynamic>?)?['bus_platenumber'] as String?;
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

  Future<void> _refresh() async {
    fetchOptionsFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    bool isDestinationChosen = selectedOption != 'Choose Bus Plate Number';
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Bus Status')),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profile()),
              );
            },
            icon: Icon(Icons.person),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('sign in as: ' + user.email!),
              MaterialButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                color: Colors.blue,
                child: Text(
                  'sign out',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
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
                                GeoPoint? driverLocation = (snapshot.data!
                                        .data() as Map<String, dynamic>?)?[
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
                                            fontSize: 10,
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

                                                    if (selectedOption !=
                                                        null) {
                                                      // Update the selected bus plate number in Firestore
                                                      FirebaseFirestore.instance
                                                          .collection('Driver')
                                                          .doc('driver1')
                                                          .update({
                                                        'bus_id': selectedOption
                                                      });
                                                    }
                                                  },
                                                );
                                              },
                                        underline:
                                            Container(), // Remove the default underline
                                        items: options
                                            .map<DropdownMenuItem<String>>(
                                          (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
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
              if (!isDestinationChosen)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(20, 0, 0, 20),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String busPlateNumber =
                                    ''; // Variable to hold the entered bus plate number
                                return AlertDialog(
                                  title: Text('Insert Bus Plate Number'),
                                  content: Container(
                                    height: 20,
                                    child: TextField(
                                      onChanged: (value) {
                                        busPlateNumber =
                                            value; // Update the bus plate number as the user types
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter Bus Plate Number',
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Add the bus plate number to Firestore
                                        FirebaseFirestore.instance
                                            .collection('Bus')
                                            .doc(busPlateNumber)
                                            .set({
                                          'bus_platenumber': busPlateNumber,
                                          'bus_numberpassenger': 0
                                        });

                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                      },
                                      child: Text('Add'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 40, color: Colors.blue),
                                Text(
                                  'Add New',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: ElevatedButton(
                          onPressed: () {
                            // Fetch the list of bus plate numbers from Firestore
                            FirebaseFirestore.instance
                                .collection('Bus')
                                .get()
                                .then((QuerySnapshot querySnapshot) {
                              List<String> busPlateNumbers = [];
                              querySnapshot.docs.forEach((doc) {
                                busPlateNumbers.add(doc['bus_platenumber']);
                              });

                              // Show a dialog with the list of bus plate numbers
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        'Select Bus Plate Number to Delete'),
                                    content: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: busPlateNumbers.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return ListTile(
                                          title: Text(busPlateNumbers[index]),
                                          onTap: () {
                                            // Delete the selected bus plate number from Firestore
                                            FirebaseFirestore.instance
                                                .collection('Bus')
                                                .where('bus_platenumber',
                                                    isEqualTo:
                                                        busPlateNumbers[index])
                                                .get()
                                                .then((QuerySnapshot snapshot) {
                                              snapshot.docs.forEach((doc) {
                                                doc.reference.delete();
                                              });
                                            });

                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                        );
                                      },
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete,
                                    size: 40, color: Colors.blue),
                                Text(
                                  'Delete Existing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              if (isDestinationChosen)
                Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isButtonPressed = true;
                                  });
                                  startUpdatingLocation();
                                },
                                child: Text(
                                  'Start Driving',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              height: 50,
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isButtonPressed = false;
                                  });
                                  stopUpdatingLocation();
                                },
                                child: Text(
                                  'Stop Driving',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Passenger()),
                                  );
                                },
                                child: Text(
                                  'View Passenger List',
                                  style: TextStyle(fontSize: 18.0),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
