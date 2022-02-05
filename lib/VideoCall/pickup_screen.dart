import 'package:flash_chat/VideoCall/call_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'call.dart';
import 'call_screen.dart';
import 'package:flash_chat/VideoCall/permissions.dart';
import 'package:audioplayers/audioplayers.dart';

class PickupScreen extends StatefulWidget {
  final Call call;
  PickupScreen({@required this.call});

  @override
  _PickupScreenState createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final CallMethods callMethods = CallMethods();

  AudioCache player = AudioCache();
  AudioPlayer stopPlayer;

  @override
  void initState() {
    super.initState();
    play();
  }

  void play() async {
    stopPlayer = await player.loop('Ringtone.mp3');
  }

  void stop() async {
    await stopPlayer?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Incoming...',
              style: TextStyle(fontSize: 30.0),
            ),
            SizedBox(height: 50.0),
            Text(
              widget.call.callerName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            SizedBox(height: 70.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.call_end),
                  color: Colors.redAccent,
                  onPressed: () async {
                    await callMethods.endCall(call: widget.call);
                    stop();
                  },
                ),
                SizedBox(width: 25.0),
                IconButton(
                    icon: Icon(Icons.call),
                    color: Colors.green,
                    onPressed: () async {
                      stop();
                      await Permissions.cameraAndMicrophonePermissionsGranted()
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CallScreen(call: widget.call)))
                          // ignore: unnecessary_statements
                          : {};
                    })
              ],
            )
          ],
        ),
      ),
    );
  }
}
