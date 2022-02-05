class PrivateUser {
  String uid;
  String name;
  String email;
  int state;

  PrivateUser({
    this.uid,
    this.name,
    this.email,
    this.state,
  });

  Map toMap(PrivateUser user) {
    var data = Map<String, dynamic>();
    data['uid'] = user.uid;
    data['name'] = user.name;
    data['email'] = user.email;
    data["state"] = user.state;
    return data;
  }

  // Named constructor
  PrivateUser.fromMap(Map<String, dynamic> mapData, String uid) {
    this.uid = uid;
    this.name = mapData['User Name'];
    this.email = uid;
    this.state = mapData['state'];
  }
}
