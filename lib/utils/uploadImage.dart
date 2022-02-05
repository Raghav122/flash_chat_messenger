import 'package:flash_chat/utils/hiroku_postRequest.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance; // ignore: deprecated_member_use
User loggedinuser = FirebaseAuth.instance.currentUser;
String message = '';
String documentId;

class UploadingImageToFirebase extends StatefulWidget {
  UploadingImageToFirebase({
    @required this.RecieverEmail,
    @required this.RecieverName,
    @required this.groupChatId,
    @required this.Id,
    @required this.Token,
  });
  final String RecieverEmail, RecieverName, groupChatId, Id, Token;
  static const String id = 'uploadImage';
  @override
  _UploadingImageToFirebaseState createState() =>
      _UploadingImageToFirebaseState();
}

class _UploadingImageToFirebaseState extends State<UploadingImageToFirebase> {
  File _imageFile;
  final picker = ImagePicker();
  bool showspinner = false;

  Future<void> pickImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> openCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = basename(_imageFile.path);
    final Reference firebasestorereference =
        FirebaseStorage.instance.ref().child(fileName);

    await firebasestorereference.putFile(_imageFile);

    String url = await firebasestorereference.getDownloadURL();
    message = '$url';
    if (message.trim() != '') {
      var groupCatID = widget.groupChatId;
      var documentReference = FirebaseFirestore.instance
          .collection('messageStore')
          .doc(groupCatID)
          .collection(groupCatID)
          .doc(DateTime.now().microsecondsSinceEpoch.toString());

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(documentReference, {
          'idFrom': widget.Id,
          'idTo': widget.RecieverEmail,
          'timeStamp': DateTime.now().microsecondsSinceEpoch.toString(),
          'content': message,
          'type': 2,
        });
      });
      await fcmNotification(
          'Image', FirebaseAuth.instance.currentUser.displayName, widget.Token);
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.Id)
          .collection('contacts')
          .doc(widget.RecieverEmail)
          .set({'User Name': widget.RecieverName});
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.RecieverEmail)
          .collection('contacts')
          .doc(widget.Id)
          .set({'User Name': FirebaseAuth.instance.currentUser.displayName});
      setState(() {
        message = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⚡️Chat'),
        backgroundColor: Colors.green,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showspinner,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                  // height: 400.0,
                  // width: 400.0,
                  child: _imageFile != null
                      ? Image.file(_imageFile)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: FlatButton(
                                child: Icon(
                                  Icons.insert_photo,
                                  size: 75,
                                ),
                                onPressed: pickImage,
                              ),
                            ),
                            Center(
                              child: FlatButton(
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 75,
                                ),
                                onPressed: openCamera,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.0),
                  child: Container(
                    color: Colors.green,
                    child: FlatButton(
                      child: Text(
                        'Send',
                        style: TextStyle(fontSize: 20.0, color: Colors.white),
                      ),
                      onPressed: () async {
                        setState(() {
                          showspinner = true;
                        });
                        if (_imageFile == null) {
                          setState(() {
                            showspinner = false;
                          });
                        }
                        await uploadImageToFirebase(context);
                        setState(() {
                          showspinner = false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
