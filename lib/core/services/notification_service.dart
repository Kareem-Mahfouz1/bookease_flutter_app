import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final FirebaseFirestore _firestore;
  final void Function(String bookingId)? onReminderTapped;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  NotificationService(this._firestore, {this.onReminderTapped});

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveToken();
    }

    _firebaseMessaging.onTokenRefresh.listen(_updateToken);

    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message, fromForeground: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, fromForeground: false);
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, fromForeground: false);
    }
  }

  void _handleMessage(RemoteMessage message, {required bool fromForeground}) {
    final type = message.data['type'];
    if (type == 'appointment_reminder') {
      final bookingId = message.data['bookingId'];
      if (!fromForeground) {
        onReminderTapped?.call(bookingId);
      }
    }
  }

  Future<void> _saveToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token == null || token.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> _updateToken(String token) async {
    if (token.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
