import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/VideoCall/private_user.dart';
import 'package:flutter/cupertino.dart';

final CollectionReference _userCollection =
    FirebaseFirestore.instance.collection("messages");

Future<User> getCurrentUser() async {
  User currentUser;
  currentUser = FirebaseAuth.instance.currentUser;
  return currentUser;
}

Future<PrivateUser> getUserDetails() async {
  User currentUser = await getCurrentUser();
  var name = currentUser.displayName;
  print('current --------------------------------------$name');
  DocumentSnapshot documentSnapshot =
      await _userCollection.doc(currentUser.email).get();
  var v = documentSnapshot.data();
  print('data--------------------------------$v');
  return PrivateUser.fromMap(documentSnapshot.data(), currentUser.email);
}

class UserProvider with ChangeNotifier {
  PrivateUser _user;
  PrivateUser get getUser => _user;

  void refreshUser() async {
    PrivateUser user = await getUserDetails();
    _user = user;
    var name = user.name;
    print('user ------------------------------------ $name');
    notifyListeners();
  }
}
