import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection and stream helpers used by the HDP Laundry app.
class FirebaseStore {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');
  static CollectionReference<Map<String, dynamic>> get services =>
      db.collection('services');
  static CollectionReference<Map<String, dynamic>> get orders =>
      db.collection('orders');

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() =>
      users.snapshots();
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchServices() =>
      services.snapshots();
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders() =>
      orders.snapshots();
}
