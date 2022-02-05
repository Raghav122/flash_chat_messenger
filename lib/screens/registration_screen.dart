import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flash_chat/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'contact_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User _user = FirebaseAuth.instance.currentUser;

  bool showSpinner = false;
  String email;
  String password;
  bool isSignIn = false;

  Future<String> signInwithGoogle() async {
    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication
            .accessToken); // ignore: deprecated_member_use

    final UserCredential result = await _auth.signInWithCredential(credential);

    _user = result.user;

    if (_user != null) {
      assert(!_user.isAnonymous);
      assert(await _user.getIdToken() != null);

      final User currentUser = _auth.currentUser;
      assert(_user.uid == currentUser.uid);
      return '$_user';
    }

    return null;
  }

  Future<void> signOutGoogle() async {
    await FirebaseAuth.instance.signOut();
    // await _googleSignIn.signOut();
    print("User Signed Out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              Center(
                child: Material(
                  elevation: 7.0,
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  child: FlatButton(
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      await signInwithGoogle().then((value) async {
                        if (value != null) {
                          var loggedInUserN =
                              await FirebaseAuth.instance.currentUser;
                          print(
                              'useremail ------------------------ $loggedInUserN ------');
                          var token =
                              await FirebaseMessaging.instance.getToken();
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(loggedInUserN.email)
                              .set({
                            'User Name': loggedInUserN.displayName,
                            'Token': token,
                          });
                        }
                        Navigator.pushNamed(context, HomeScreen.id);
                        setState(() {
                          showSpinner = false;
                        });
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(10.0, 1.0, 20.0, 1.0),
                              height: 30.0,
                              child: Image.asset('images/google.jpg'),
                            ),
                            Text(
                              'Sign in with Google',
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                          ]),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}
