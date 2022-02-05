class Call {
  String callerId;
  String callerName;
  String recieverId;
  String recieverName;
  String channelId;
  bool hasDialled;

  Call({
    this.callerId,
    this.callerName,
    this.channelId,
    this.hasDialled,
    this.recieverId,
    this.recieverName,
  });

  Map<String, dynamic> toMap(Call call) {
    Map<String, dynamic> callMap = Map();
    callMap["caller_id"] = call.callerId;
    callMap["caller_name"] = call.callerName;
    callMap["reciever_name"] = call.recieverName;
    callMap["reciever_id"] = call.recieverId;
    callMap["channel_id"] = call.channelId;
    callMap["has_dialled"] = call.hasDialled;
    return callMap;
  }

  Call.fromMap(Map callMap) {
    this.callerId = callMap["caller_id"];
    this.callerName = callMap["caller_name"];
    this.recieverName = callMap["reciever_name"];
    this.recieverId = callMap["reciever_id"];
    this.channelId = callMap["channel_id"];
    this.hasDialled = callMap["has_dialled"];
  }
}
