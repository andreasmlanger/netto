import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'screens/carousel.dart';
import 'services/database.dart';
import 'services/local_notifications.dart';
import 'services/local_time_zone.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await configureLocalTimeZone();
  NotificationService notificationService = NotificationService(navigatorKey: navigatorKey);
  await notificationService.initNotification();

  runApp(MyApp(
    flutterLocalNotificationsPlugin: notificationService.notificationsPlugin,
  ));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const MyApp({
    Key? key,
    required this.flutterLocalNotificationsPlugin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: StreamProvider<QuerySnapshot<Object?>?>.value(
          value: DatabaseService().coupons,
          initialData: null,
          child: const CouponCarousel()
        ),
      ),
    );
  }
}
