import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {

  final CollectionReference couponCollection = FirebaseFirestore.instance.collection('Coupons');

  // Get coupon stream from Firestore Database
  Stream<QuerySnapshot> get coupons {
    return couponCollection.snapshots();
  }
}
