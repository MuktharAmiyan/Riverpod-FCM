import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_notification/notification/firebase_messanging_provider.dart';
import 'package:flutter_notification/notification/local_push_notifiaction.dart';
import 'package:flutter_notification/notification/model/recived_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  log("Handling a background message: ${message.messageId}");
}

final firebasePushnotificationProvider =
    Provider<FirebasePushNotifiaction>((ref) {
  final messaging = ref.watch(firebaseMessangingProvider);
  final notificaton = ref.watch(loaclPushNotificationProvider);
  return FirebasePushNotifiaction(messaging, notificaton);
});

class FirebasePushNotifiaction {
  final FirebaseMessaging messaging;
  final LocalPushNotification localPushNotification;
  FirebasePushNotifiaction(this.messaging, this.localPushNotification) {
    _init();
    _onFirebaseMessageRecived();
  }

  void _init() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    log('User granted permission: ${settings.authorizationStatus}');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _onFirebaseMessageRecived() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        Map<String, dynamic> data = message.data;

        if (notification != null && android != null) {
          localPushNotification.showNotification(
            RecivedNotification(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              imageUrl: android.imageUrl,
              payload: jsonEncode(data),
            ),
          );
        }
      },
    );
  }
}
