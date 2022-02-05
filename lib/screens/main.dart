import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flash_chat/screens/ImageViewingScreen.dart';
import 'package:flash_chat/VideoCall/user_provider.dart';
import 'package:flash_chat/screens/contact_screen.dart';
import 'package:flash_chat/screens/home_screen.dart';
import 'package:flash_chat/utils/uploadImage.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<bool> islogged() async {
    try {
      final User user = await _firebaseAuth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final Auth _auth = Auth();
  final bool islogged = await _auth.islogged();
  runApp(FlashChat(islogged: islogged));
}

class FlashChat extends StatefulWidget with WidgetsBindingObserver {
  FlashChat({@required this.islogged});

  final bool islogged;

  @override
  _FlashChatState createState() => _FlashChatState();
}

class _FlashChatState extends State<FlashChat> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(FirebaseAuth.instance.currentUser.email)
          .update({
        'state': 0,
      });
    } else if (state == AppLifecycleState.resumed) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(FirebaseAuth.instance.currentUser.email)
          .update({
        'state': 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: widget.islogged ? HomeScreen.id : WelcomeScreen.id,
        routes: {
          WelcomeScreen.id: (context) => WelcomeScreen(),
          LoginScreen.id: (context) => LoginScreen(),
          RegistrationScreen.id: (context) => RegistrationScreen(),
          ChatScreen.id: (context) => ChatScreen(),
          UploadingImageToFirebase.id: (context) => UploadingImageToFirebase(),
          ImageView.id: (context) => ImageView(),
          ContactScreen.id: (context) => ContactScreen(),
          HomeScreen.id: (context) => HomeScreen(),
        },
      ),
    );
  }
}
