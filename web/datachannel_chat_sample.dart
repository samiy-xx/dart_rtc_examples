import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';

//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
void main() {
  var key = query("#key").text;
  int channelLimit = 10;
  Element c = query("#container");
  Notifier notifier = new Notifier();
  DivElement chat_output = query("#chat_output");
  DivElement chat_input = query("#chat_input");
  DivElement chat_users = query("#chat_users");
  final int KEY_ENTER = 13;

  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  //.setChannel("abc")
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true);

  chat_input.onKeyUp.listen((KeyboardEvent e) {
    if (e.keyCode == KEY_ENTER) {

      var entry = createChatEntry(new DateTime.now().toString(), "ME", chat_input.text);
      chat_output.append(entry);
      chat_output.scrollTop = chat_output.scrollHeight;

      if (chat_input.text.startsWith("/")) {
        List<String> l = chat_input.text.split(" ");
        String target = l[1];
        List<String> remains = l.sublist(2);
        try {
          // Copypaste the name of the target seems to cause interesting effects
          // try catch to quick fix =)

          if (target != qClient.myId) {
            print("$target ${qClient.myId}");
            if (qClient.peerManager.findWrapper(target) == null) {
              qClient.createPeerConnection(target);
            }
            //qClient.sendPeerUserMessage(target, remains.join(" "));
            String toSend = remains.join(" ");
            qClient.sendArrayBufferReliable(target, BinaryData.bufferFromString(toSend));
          }
        } catch(e){}
      } else {
        qClient.sendChannelMessage(chat_input.text);
      }

      chat_input.text = "";
      return;
    }
  });

  qClient.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {

    if (e.state == InitializationState.CHANNEL_READY) {
      if (!qClient.setChannelLimit(channelLimit)) {
        notifier.display("Failed to set new channel user limit");
      }
    }
    if (e.state == InitializationState.REMOTE_READY) {
      qClient.joinChannel(key);
    }
  });

  qClient.onSignalingStateChanged.listen((SignalingStateEvent e) {
    if (e.state == Signaler.SIGNALING_STATE_OPEN) {
      notifier.display("Signaling connected to server");
      chat_input.contentEditable = "true";
      chat_input.classes.remove("input_inactive");
      chat_input.classes.add("input_active");
      var entry = createChatEntry(new DateTime.now().toString(), "SYSTEM", "Connected to server");
      chat_output.append(entry);
      chat_output.scrollTop = chat_output.scrollHeight;
    } else if (e.state == Signaler.SIGNALING_STATE_CLOSED){
      notifier.display("Signaling connection to server has closed");
      chat_input.classes.remove("input_active");
      chat_input.classes.add("input_inactive");
      chat_input.contentEditable = "false";
      chat_users.nodes.clear();
      var entry = createChatEntry(new DateTime.now().toString(), "SYSTEM", "Disconnected from server");
      chat_output.append(entry);
      chat_output.scrollTop = chat_output.scrollHeight;

      new Timer(const Duration(milliseconds: 10000), () {
        notifier.display("Attempting to reconnect to server");
        qClient.initialize();
      });
    }
  });

  qClient.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
      var entry = createPrivateEntry(new DateTime.now().toString(), bbc.peer.id, BinaryData.stringFromBuffer(bbc.buffer));
      chat_output.append(entry);
      chat_output.scrollTop = chat_output.scrollHeight;
      notifier.display("Private peer message from ${bbc.peer.id}");
    }
  });

  qClient.onServerEvent.listen((ServerEvent e) {
    if (e is ServerJoinEvent) {
      ServerJoinEvent p = e;
      var entry = createChatEntry(new DateTime.now().toString(), "CHANNEL", "Welcome to channel ${p.channel}. Channel  has a limit of ${p.limit} concurrent users");
      chat_output.append(entry);
    }
    else if (e is ServerParticipantJoinEvent) {
      ServerParticipantJoinEvent p = e;
      DivElement u = createUserEntry(p.id);
      chat_users.append(u);
      var entry = createChatEntry(new DateTime.now().toString(), "SYSTEM", "${p.id} joins the channel");
      chat_output.append(entry);
      u.onDoubleClick.listen((MouseEvent e) {
        if (chat_input.text == "") {
          chat_input.text = "/msg ${u.id}";
        }
      });
    }

    else if (e is ServerParticipantIdEvent) {
      ServerParticipantIdEvent p = e;
      DivElement u = createUserEntry(p.id);
      chat_users.append(u);
      u.onDoubleClick.listen((MouseEvent e) {
        if (chat_input.text == "") {
          chat_input.text = "/msg ${u.id}";
        }
      });
    }

    else if (e is ServerParticipantLeftEvent) {
      ServerParticipantLeftEvent p = e;
      removeUserEntry(chat_users, p.id);
      var entry = createChatEntry(new DateTime.now().toString(), "SYSTEM", "${p.id} leaves the channel");
      chat_output.append(entry);
    }

    else if (e is ServerChannelMessageEvent) {
      ServerChannelMessageEvent p = e;
      var entry = createChatEntry(new DateTime.now().toString(), p.id, p.message);
      chat_output.append(entry);
      chat_output.scrollTop = chat_output.scrollHeight;
    }
  });



  qClient.initialize();
}

DivElement createChatEntry(String time, String id, String message) {
  DivElement entry = new DivElement();
  entry.classes.add("output_entry");

  var span_time = new SpanElement();
  span_time.classes.add("timestamp");
  span_time.appendText(time);

  var span_name = new SpanElement();
  span_name.classes.add("name");
  span_name.appendText("< $id >");

  var span_message = new SpanElement();
  span_message.classes.add("message");
  span_message.appendText(message);

  entry.append(span_time);
  entry.append(span_name);
  entry.append(span_message);

  return entry;
}
DivElement createPrivateEntry(String time, String id, String message) {
  DivElement entry = new DivElement();
  entry.classes.add("output_entry");
  entry.classes.add("private_message");
  var span_time = new SpanElement();
  span_time.classes.add("timestamp");
  span_time.appendText(time);

  var span_name = new SpanElement();
  span_name.classes.add("name");
  span_name.appendText("(PM)< $id >");

  var span_message = new SpanElement();
  span_message.classes.add("message");
  span_message.appendText(message);

  entry.append(span_time);
  entry.append(span_name);
  entry.append(span_message);

  return entry;
}
void pruneEntries() {

}

DivElement createUserEntry(String id) {
  DivElement user = new DivElement();
  user.classes.add("user_entry");
  user.id = id;
  user.appendText(id);
  user.style.cursor = "pointer";
  return user;
}

void removeUserEntry(DivElement e, String id) {
  for (int i = 0; i < e.nodes.length; i++) {
    Element element = e.nodes[i];
    if (element.id == id) {
      e.nodes.removeAt(i);
    }
  }
}
