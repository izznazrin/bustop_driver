import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Passenger extends StatefulWidget {
  const Passenger({Key? key}) : super(key: key);

  @override
  State<Passenger> createState() => _PassengerState();
}

class _PassengerState extends State<Passenger> {
  Stream<QuerySnapshot<Map<String, dynamic>>> getPassengersStream() {
    return FirebaseFirestore.instance
        .collection('Passenger')
        .where('passenger_inbus', isEqualTo: true)
        .snapshots();
  }

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
                        'Passenger In Bus:',
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
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: getPassengersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final passengerCount = snapshot.data!.size;
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getPassengersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final passengers = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: passengers.length,
                    itemBuilder: (context, index) {
                      final passenger = passengers[index];
                      final passengerName = passenger['student_name'];

                      final passengerDestination =
                          passenger['passenger_destination'];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text(passengerName),
                            subtitle: Text(passengerDestination),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'Error retrieving passengers',
                    style: TextStyle(fontSize: 18),
                  );
                } else {
                  return CircularProgressIndicator(); // Display a loading indicator while waiting for data
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
