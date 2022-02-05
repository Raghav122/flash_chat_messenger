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
import 'main.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key key}) : super(key: key);

  static const String id = 'contact_screen';

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
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
                        onPressed: () {
                          signOutGoogle();
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
      ),
    );
  }
}

class NameStream extends StatelessWidget {
  const NameStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.green,
            ),
          );
        }
        final Names = snapshot.data.docs;
        List<NameBox> nameBox = [];
        for (var names in Names) {
          Map<dynamic, dynamic> v = names.data();
          final displayName = v['User Name'];
          final token = v['Token'];
          final docid = names.id;
          final state = v['state'];
          print(
              '--------------------$displayName  --------state  ---- $state-');
          if (docid != (FirebaseAuth.instance.currentUser.email)) {
            final namebox = NameBox(
                name: displayName, docId: docid, token: token, state: state);
            nameBox.add(namebox);
          }
        }
        return Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: nameBox,
          ),
        );
      },
    );
  }
}

class NameBox extends StatelessWidget {
  NameBox({this.docId, this.name, this.token, this.state});

  String docId, name, token;
  int state;

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
