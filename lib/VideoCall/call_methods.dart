import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/VideoCall/call.dart';

class CallMethods {
  final CollectionReference callCollection =
      FirebaseFirestore.instance.collection("call");

  Stream<DocumentSnapshot> callStream({String uid}) =>
      callCollection.doc(uid).snapshots();

  Future<bool> makeCall({Call call}) async {
    try {
      call.hasDialled = true;
      Map<String, dynamic> hasDialledMap = call.toMap(call);
      call.hasDialled = false;
      Map<String, dynamic> hasNotDialledMap = call.toMap(call);
      await callCollection.doc(call.callerId).set(hasDialledMap);
      await callCollection.doc(call.recieverId).set(hasNotDialledMap);
      return true;
    } catch (e) {
      print("--------------------------------3546$e");
      return false;
    }
  }

  Future<bool> endCall({Call call}) async {
    try {
      await callCollection.doc(call.callerId).delete();
      await callCollection.doc(call.recieverId).delete();
      return true;
    } catch (e) {
      print("--------------------------------4546$e");
      return false;
    }
  }
}
