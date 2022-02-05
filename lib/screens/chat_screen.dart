import 'package:cached_network_image/cached_network_image.dart';
import 'package:flash_chat/screens/ImageViewingScreen.dart';
import 'package:flash_chat/VideoCall/pickup_layout.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/utils/hiroku_postRequest.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flash_chat/utils/uploadImage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flash_chat/utils/Location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash_chat/VideoCall/call_utilities.dart';
import 'package:flash_chat/VideoCall/private_user.dart';
import 'package:flash_chat/VideoCall/permissions.dart';

final _firestore = FirebaseFirestore.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();
User loggedinuser = FirebaseAuth.instance.currentUser;
bool spinner = false;
final url = 'https://www.google.com/maps/search/?api=1&query=';

class ChatScreen extends StatefulWidget {
  // ignore: non_constant_identifier_names
  ChatScreen(
      {@required this.RecieverEmail,
      @required this.RecieverName,
      @required this.token});
  // ignore: non_constant_identifier_names
  final String RecieverEmail, RecieverName, token;
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String RecieverEmail, RecieverName;
  final _auth = FirebaseAuth.instance;
  String message = '';
  File _imageFile;
  final picker = ImagePicker();
  double _latitude;
  double _longitude;
  GoogleMapController _controller;
  Location _location = Location();
  List<QueryDocumentSnapshot> listMessage = new List.from([]);
  String groupChatId, id, imageUrl;
  SharedPreferences prefs;
  String deleteMessageAddress;
  PrivateUser sender;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    id = FirebaseAuth.instance.currentUser.email;
    String tempReciever = widget.RecieverEmail;
    if (id.hashCode <= widget.RecieverEmail.hashCode) {
      groupChatId = '$id-$tempReciever';
    } else {
      groupChatId = '$tempReciever-$id';
    }
    setState(() {
      sender = PrivateUser(
        uid: loggedinuser.uid,
        name: loggedinuser.displayName,
      );
    });
    readLocal();
    RecieverName = widget.RecieverName;
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = FirebaseAuth.instance.currentUser.email;
    String tempReciever = widget.RecieverEmail;
    if (id.hashCode <= widget.RecieverEmail.hashCode) {
      groupChatId = '$id-$tempReciever';
    } else {
      groupChatId = '$tempReciever-$id';
    }
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(id)
        .update({'chattingWith': widget.RecieverEmail});
  }

  void onSendMessage(String content, int type) async {
    //type : 0 = text , 1 = map , 2 = image

    if (content.trim() != '') {
      nameHolder.clear();
      var documentReference = await FirebaseFirestore.instance
          .collection('messageStore')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(DateTime.now().microsecondsSinceEpoch.toString());

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(documentReference, {
          'idFrom': id,
          'idTo': widget.RecieverEmail,
          'timeStamp': DateTime.now().microsecondsSinceEpoch.toString(),
          'content': content,
          'type': type,
        });
      });
      await fcmNotification(
          content, FirebaseAuth.instance.currentUser.displayName, widget.token);
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(id)
          .collection('contacts')
          .doc(widget.RecieverEmail)
          .set({'User Name': widget.RecieverName});
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.RecieverEmail)
          .collection('contacts')
          .doc(id)
          .set({'User Name': FirebaseAuth.instance.currentUser.displayName});
    }
  }

  void onSendLocation(String url, int type) async {
    if (url.trim() != '') {
      var docRef = await FirebaseFirestore.instance
          .collection('messageStore')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(DateTime.now().microsecondsSinceEpoch.toString());

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(docRef, {
          'idFrom': id,
          'idTo': widget.RecieverEmail,
          'timeStamp': DateTime.now().microsecondsSinceEpoch.toString(),
          'content': url,
          'type': type,
        });
      });
      await fcmNotification('My Location',
          FirebaseAuth.instance.currentUser.displayName, widget.token);
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(id)
          .collection('contacts')
          .doc(widget.RecieverEmail)
          .set({'User Name': widget.RecieverName});
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.RecieverEmail)
          .collection('contacts')
          .doc(id)
          .set({'User Name': FirebaseAuth.instance.currentUser.displayName});
    }
  }

  void launchUrl(String url) async => await launch(url);

  Widget buildItem(int index, DocumentSnapshot document) {
    Map<dynamic, dynamic> map = document.data();
    if (map['idFrom'] == id) {
      return Padding(
        padding: EdgeInsets.all(6.0),
        child: map['type'] == 0
            ?
            //text
            Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextButton(
                          onLongPress: () {
                            setState(() {
                              showDefaultAppBar = 1;
                              deleteMessageAddress = document.id;
                            });
                          },
                          onPressed: () {
                            if (showDefaultAppBar == 1) {
                              setState(() {
                                showDefaultAppBar = 0;
                                deleteMessageAddress = null;
                              });
                            }
                          },
                          child: Container(
                            child: Material(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.0),
                                  bottomLeft: Radius.circular(30.0),
                                  bottomRight: Radius.circular(30.0)),
                              elevation: 7.0,
                              color: deleteMessageAddress == document.id
                                  ? Colors.blueAccent
                                  : Colors.green,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 20),
                                child: Text(
                                  map['content'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm').format(
                          DateTime.fromMicrosecondsSinceEpoch(
                              int.parse(map['timeStamp']))),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(right: 30.0, top: 5.0, bottom: 5.0),
                  )
                ],
              )
            : map['type'] == 2
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.only(top: 7.0, bottom: 7.0, left: 40.0),
                        child: Material(
                          color: deleteMessageAddress == document.id
                              ? Colors.blueAccent
                              : Colors.green,
                          elevation: 7.0,
                          child: Padding(
                            padding: EdgeInsets.all(1.0),
                            child: TextButton(
                              onLongPress: () {
                                setState(() {
                                  showDefaultAppBar = 1;
                                  deleteMessageAddress = document.id;
                                });
                              },
                              onPressed: () {
                                if (showDefaultAppBar == 1) {
                                  setState(() {
                                    showDefaultAppBar = 0;
                                    deleteMessageAddress = null;
                                  });
                                } else {
                                  var URL = map['content'];
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ImageView(url: URL)));
                                }
                              },
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green),
                                  ),
                                  width: 250.0,
                                  height: 250.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(30.0),
                                        topLeft: Radius.circular(30.0),
                                        bottomLeft: Radius.circular(30.0)),
                                  ),
                                ),
                                imageUrl: map['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                      ),
                      Container(
                        child: Text(
                          DateFormat('dd MMM kk:mm').format(
                              DateTime.fromMicrosecondsSinceEpoch(
                                  int.parse(map['timeStamp']))),
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontStyle: FontStyle.italic),
                        ),
                        margin:
                            EdgeInsets.only(right: 30.0, top: 5.0, bottom: 5.0),
                      )
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: 65.0,
                              child: Material(
                                color: deleteMessageAddress == document.id
                                    ? Colors.blueAccent
                                    : Colors.green,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30.0),
                                    bottomLeft: Radius.circular(30.0),
                                    bottomRight: Radius.circular(30.0)),
                                elevation: 7.0,
                                child: TextButton(
                                  onLongPress: () {
                                    setState(() {
                                      showDefaultAppBar = 1;
                                      deleteMessageAddress = document.id;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 10.0),
                                    child: Text(
                                      'My Location',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 23.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (showDefaultAppBar == 1) {
                                      setState(() {
                                        showDefaultAppBar = 0;
                                        deleteMessageAddress = null;
                                      });
                                    } else {
                                      var location = map['content'];
                                      await launchUrl(location);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: Text(
                          DateFormat('dd MMM kk:mm').format(
                              DateTime.fromMicrosecondsSinceEpoch(
                                  int.parse(map['timeStamp']))),
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontStyle: FontStyle.italic),
                        ),
                        margin:
                            EdgeInsets.only(right: 30.0, top: 5.0, bottom: 5.0),
                      )
                    ],
                  ),
      );
    } else {
      Map<dynamic, dynamic> map = document.data();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: map['type'] == 0
                ? Padding(
                    padding: EdgeInsets.only(right: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Material(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30.0),
                                bottomLeft: Radius.circular(30.0),
                                bottomRight: Radius.circular(30.0)),
                            elevation: 7.0,
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 20),
                              child: Text(
                                map['content'],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          child: Text(
                            DateFormat('dd MMM kk:mm').format(
                                DateTime.fromMicrosecondsSinceEpoch(
                                    int.parse(map['timeStamp']))),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic),
                          ),
                          margin: EdgeInsets.only(
                              left: 30.0, top: 5.0, bottom: 5.0),
                        )
                      ],
                    ),
                  )
                : map['type'] == 2
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 7.0, right: 40.0, bottom: 7.0),
                            child: Material(
                              color: Colors.white54,
                              elevation: 7.0,
                              child: Padding(
                                padding: EdgeInsets.all(1.0),
                                child: TextButton(
                                  onPressed: () {
                                    var URL = map['content'];
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ImageView(url: URL)));
                                  },
                                  child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.green),
                                      ),
                                      width: 250.0,
                                      height: 250.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(30.0),
                                            topLeft: Radius.circular(30.0),
                                            bottomLeft: Radius.circular(30.0)),
                                      ),
                                    ),
                                    imageUrl: map['content'],
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                          ),
                          Container(
                            child: Text(
                              DateFormat('dd MMM kk:mm').format(
                                  DateTime.fromMicrosecondsSinceEpoch(
                                      int.parse(map['timeStamp']))),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic),
                            ),
                            margin: EdgeInsets.only(
                                left: 30.0, top: 5.0, bottom: 5.0),
                          )
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 65.0,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(30.0),
                                    bottomLeft: Radius.circular(30.0),
                                    bottomRight: Radius.circular(30.0)),
                                elevation: 7.0,
                                child: TextButton(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 10.0),
                                    child: Text(
                                      'My Location',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 23.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  onPressed: () async {
                                    var location = map['content'];
                                    await launchUrl(location);
                                  },
                                ),
                              ),
                            ),
                            Container(
                              child: Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMicrosecondsSinceEpoch(
                                        int.parse(map['timeStamp']))),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic),
                              ),
                              margin: EdgeInsets.only(
                                  left: 30.0, top: 5.0, bottom: 5.0),
                            )
                          ],
                        ),
                      ),
          ),
        ],
      );
    }
  }

  bool isLastMessageLeft(int index) {
    Map<dynamic, dynamic> temp = listMessage[index].data();
    if ((index > 0 && listMessage != null && temp['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    Map<dynamic, dynamic> temp = listMessage[index].data();
    if ((index > 0 && listMessage != null && temp['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    FirebaseFirestore.instance
        .collection('messages')
        .doc(id)
        .update({'chattingWith': ''});
    Navigator.pop(context);

    return Future.value(false);
  }

  Widget buildList() {
    return Flexible(
      child:
          StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('messageStore')
            .doc(groupChatId)
            .collection(groupChatId)
            .orderBy('timeStamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green)));
          } else {
            listMessage.addAll(snapshot.data.docs);
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              itemBuilder: (context, index) =>
                  buildItem(index, snapshot.data.docs[index]),
              itemCount: snapshot.data.docs.length,
              reverse: true,
            );
          }
        },
      ),
    );
  }

  Widget stateChecker() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(
                left: 143.0, right: 143.0, top: 5.0, bottom: 5.0),
            child: Container(
              height: 30.0,
              width: 40.0,
              child: Material(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  elevation: 12.0,
                  child: Text(
                    'Offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  )),
            ),
          );
        }
        final states = snapshot.data.docs;
        var stateCheck;
        for (var state in states) {
          Map<dynamic, dynamic> v = state.data();
          if (state.id == widget.RecieverEmail) {
            stateCheck = v['state'];
          }
        }
        return stateCheck == 1
            ? Padding(
                padding: const EdgeInsets.only(
                    left: 143.0, right: 143.0, top: 5.0, bottom: 5.0),
                child: Container(
                  height: 30.0,
                  width: 40.0,
                  child: Material(
                      borderRadius: BorderRadius.circular(5.0),
                      color: Colors.white,
                      elevation: 12.0,
                      child: Text(
                        'Online',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      )),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(
                    left: 143.0, right: 143.0, top: 5.0, bottom: 5.0),
                child: Container(
                  height: 30.0,
                  width: 40.0,
                  child: Material(
                      borderRadius: BorderRadius.circular(5.0),
                      color: Colors.white,
                      elevation: 12.0,
                      child: Text(
                        'Offline',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      )),
                ),
              );
      },
    );
  }

  void getCurrentUser() async {
    try {
      // ignore: await_only_futures
      final user = await _auth.currentUser;
      if (user != null) {
        loggedinuser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = File(pickedFile.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadingImageToFirebase(
            RecieverEmail: widget.RecieverEmail,
            RecieverName: widget.RecieverName,
            groupChatId: groupChatId,
            Id: FirebaseAuth.instance.currentUser.email,
            Token: widget.token,
          ),
        ),
      );
    });
  }

  final nameHolder = TextEditingController();

  void clearTextInput() {
    nameHolder.clear();
  }

  int showDefaultAppBar = 0;
  AppBar newAppBar() {
    return AppBar(
      backgroundColor: Colors.green,
      actions: [
        TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('messageStore')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .doc(deleteMessageAddress)
                  .delete();
              setState(() {
                showDefaultAppBar = 0;
                deleteMessageAddress = null;
              });
            },
            child: Icon(Icons.delete, color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: WillPopScope(
        onWillPop: onBackPress,
        child: Scaffold(
          appBar: showDefaultAppBar == 0
              ? AppBar(
                  //centerTitle: true,
                  leadingWidth: 25,
                  title: Padding(
                    padding: EdgeInsets.only(left: 2.0, right: 2.0),
                    child: Text(
                      widget.RecieverName,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  actions: [
                    IconButton(
                        icon: Icon(Icons.videocam),
                        onPressed: () async => await Permissions
                                .cameraAndMicrophonePermissionsGranted()
                            ? CallUtils.dial(
                                from: sender,
                                recieverName: widget.RecieverName,
                                recieverId: widget.RecieverEmail,
                                context: context)
                            : {}),
                  ],
                )
              : newAppBar(),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/images.jpg"), fit: BoxFit.cover),
            ),
            child: ModalProgressHUD(
              inAsyncCall: spinner,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // MessageStream(ReciversEmail: widget.RecieverEmail),
                    stateChecker(),
                    buildList(),
                    SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 5.0, right: 7.0, bottom: 5.0),
                            child: Container(
                              height: 50.0,
                              decoration: kMessageContainerDecoration,
                              child: Material(
                                elevation: 7.0,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20.0)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: nameHolder,
                                        onChanged: (value) {
                                          message = value;
                                        },
                                        decoration: kMessageTextFieldDecoration,
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          minimumSize: Size.fromWidth(2.0)),
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UploadingImageToFirebase(
                                                        RecieverEmail: widget
                                                            .RecieverEmail,
                                                        RecieverName:
                                                            widget.RecieverName,
                                                        groupChatId:
                                                            groupChatId,
                                                        Id: id)));
                                      },
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          minimumSize: Size.fromWidth(2.0)),
                                      child: Icon(
                                        Icons.add_location,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          spinner = true;
                                        });
                                        await _location.getCurrentLocation();
                                        _latitude = _location.latitude;
                                        _longitude = _location.longitude;
                                        message = '$url$_latitude, $_longitude';

                                        await onSendLocation(message, 1);

                                        setState(() {
                                          spinner = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Container(
                            height: 40.0,
                            width: 40.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: TextButton(
                              onPressed: () async {
                                if (message != '') {
                                  onSendMessage(message, 0);
                                  setState(() {
                                    message = '';
                                  });
                                }
                              },
                              child: Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

showAlertDialog(BuildContext context) {
  AlertDialog alert = AlertDialog(
      title: Text('Warning'),
      content: Text(
        'Do you want to Delete this message ? ',
        style: TextStyle(
          fontSize: 20.0,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
