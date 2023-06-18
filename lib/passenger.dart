import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Passenger extends StatefulWidget {
  const Passenger({super.key});

  @override
  State<Passenger> createState() => _PassengerState();
}

Stream<int> getPassengerCountStream() {
  return FirebaseFirestore.instance
      .collection('Passenger')
      .where('passenger_inbus', isEqualTo: true)
      .snapshots()
      .map((QuerySnapshot snapshot) => snapshot.size);
}

class _PassengerState extends State<Passenger> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text('Passenger List'),
      ),
      body: SingleChildScrollView(
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
                        'Passenger In Bus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      padding: EdgeInsets.only(left: 5, right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: StreamBuilder<int>(
                          stream: getPassengerCountStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final passengerCount = snapshot.data;
                              return Text(
                                '$passengerCount',
                                style: TextStyle(fontSize: 18),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error retrieving passenger count',
                                style: TextStyle(fontSize: 18),
                              );
                            } else {
                              return CircularProgressIndicator(); // Display a loading indicator while waiting for data
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
