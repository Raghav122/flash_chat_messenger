import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flash_chat/VideoCall/pickup_layout.dart';
import 'package:flash_chat/VideoCall/user_provider.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/enums.dart'
    as ps;
import 'contact_screen.dart';
import 'main.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  static const String id = 'home_screen';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOutGoogle() async {
    var loggedin = await FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(loggedin.email)
        .set({'User Name': loggedin.displayName, 'Token': '', 'state': 0});
    await _googleSignIn.disconnect();
    await FirebaseAuth.instance.signOut();
    print("User Signed Out");
  }

  UserProvider userProvider;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUser();
      Future.delayed(Duration.zero, () {
        this.firebaseCloudMessagingListeners(context);
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification notification = message.notification;
        AndroidNotification android = message.notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channel.description,
                  color: Colors.blue,
                  playSound: true,
                  icon: '@mipmap/ic_launcher',
                ),
              ));
        }
      });
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(notification.body)],
                  ),
                ),
              );
            });
      }
    });
    updateState();
  }

  void updateState() async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(FirebaseAuth.instance.currentUser.email)
        .update({
      'state': 1,
    });
  }

  void firebaseCloudMessagingListeners(BuildContext context) {
    _firebaseMessaging.getToken().then((deviceToken) {
      print("Firebase Device Token: $deviceToken");
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      showNotification(event.notification);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      Navigator.pushNamed(context, HomeScreen.id);
    });
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'co.appbrewery.flash_chat',
      'Flash Chat',
      'Chat Notification',
      playSound: true,
      enableVibration: true,
      priority: ps.Priority.high,
      importance: Importance.max,
    );

    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(0, message.title.toString(),
        message.body.toString(), platformChannelSpecifics);
  }

  void handleClick(String value) {
    switch (value) {
      case 'Logout':
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text('Warning'),
                  content: Text('Do you want to Logout ?'),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          await signOutGoogle();
                          Navigator.popAndPushNamed(
                              context, RegistrationScreen.id);
                        },
                        child: Text('Yes')),
                    TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: Text('No')),
                  ],
                ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: Scaffold(
        appBar: AppBar(
          leading: null,
          title: Text('Flash_Chat'),
          backgroundColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              onSelected: handleClick,
              itemBuilder: (BuildContext context) {
                return {'Logout'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/imagesContact.jpg"),
                fit: BoxFit.cover),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NameStream(),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 100.0, right: 100.0, top: 10.0, bottom: 1.0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5.0),
                          topRight: Radius.circular(5.0)),
                      color: Colors.white,
                    ),
                    height: 35.0,
                    child: Material(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5.0),
                          topRight: Radius.circular(5.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 3.0, right: 2.0),
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Container(
                                width: 16.0,
                                height: 16.0,
                                decoration: BoxDecoration(
                                  color: Colors.green[900],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Text('Online  |  ', style: TextStyle(fontSize: 16.0)),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 0.0, right: 2.0),
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Container(
                                width: 16.0,
                                height: 16.0,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, ContactScreen.id);
          },
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person_add,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

class NameStream extends StatelessWidget {
  const NameStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .doc(FirebaseAuth.instance.currentUser.email)
          .collection('contacts')
          .snapshots(),
      builder: (context, snapshot1) {
        return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('messages').snapshots(),
            builder: (context, snapshot2) {
              if (!snapshot1.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.green,
                  ),
                );
              }
              final names = snapshot1.data.docs;
              final stateToken = snapshot2.data.docs;
              List<NameBox> nameBox = [];
              if (names.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: 20.0, right: 20.0, top: 50.0, bottom: 50.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      color: Colors.lightGreen[100],
                    ),
                    height: 140.0,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 5.0, right: 5.0, top: 5.0, bottom: 5.0),
                          child: Text(
                            'Start a Chat !',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 40.0,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, ContactScreen.id);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                            child: Container(
                              alignment: Alignment.center,
                              height: 50.0,
                              width: 120.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.0),
                                color: Colors.green,
                              ),
                              child: Text(
                                'Start',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              for (var names in names) {
                Map<dynamic, dynamic> v = names.data();
                var state, token;
                final displayName = v['User Name'];
                final docid = names.id;
                for (var data in stateToken) {
                  Map<dynamic, dynamic> v2 = data.data();
                  if (data.id == docid) {
                    state = v2['state'];
                    token = v2['Token'];
                  }
                }
                print(
                    '---------------------$displayName----------------------------------state $state');
                if (docid != (FirebaseAuth.instance.currentUser.email)) {
                  final namebox = NameBox(
                      name: displayName,
                      docId: docid,
                      token: token,
                      state: state);
                  nameBox.add(namebox);
                }
              }
              return Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                  children: nameBox,
                ),
              );
            });
      },
    );
  }
}

class NameBox extends StatelessWidget {
  NameBox({this.docId, this.name, this.token, this.state});

  String docId, name, token;
  var state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2.0, top: 10.0, bottom: 10.0),
      child: TextButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatScreen(
                        RecieverEmail: docId,
                        RecieverName: name,
                        token: token,
                      )));
        },
        child: Material(
          borderRadius: BorderRadius.circular(10.0),
          elevation: 7.0,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, top: 10.0),
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        '$name',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 3.0, right: 5.0),
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Container(
                        width: 13.0,
                        height: 13.0,
                        decoration: BoxDecoration(
                          color: state == 1 ? Colors.green[900] : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 5.0),
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, bottom: 10.0),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    '$docId',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
