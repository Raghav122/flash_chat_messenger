import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/VideoCall/call_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'call.dart';
import 'call_methods.dart';
import 'dart:math';
import 'private_user.dart';

class CallUtils {
  static final CallMethods callMethods = CallMethods();

  static dial(
      {PrivateUser from,
      String recieverId,
      String recieverName,
      context}) async {
    Call call = Call(
      callerId: from.uid,
      callerName: from.name,
      recieverId: recieverId,
      recieverName: recieverName,
      channelId: Random().nextInt(1000).toString(),
    );

    bool callMade = await callMethods.makeCall(call: call);
    call.hasDialled = true;
    if (callMade) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => CallScreen(call: call)));
    }
  }
}
