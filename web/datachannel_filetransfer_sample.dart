import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';

//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

void main() {
  int channelLimit = 5;
  String otherId;
  FileUploadInputElement fuie = query("#file");
  DivElement output = query("#output");
  String test = "abcdefghijklmnopqrstuvwxyz1234567890";
  ArrayBuffer buffer = BinaryData.bufferFromString(test);
  String test2 = BinaryData.stringFromBuffer(buffer);
  print(test);
  print(test2);
  new Logger().setLevel(LogLevel.ERROR);
  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  //.setChannel("abc")
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  qClient.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {

    if (e.state == InitializationState.CHANNEL_READY) {
      fuie.onChange.listen((Event e) {
        File f = fuie.files[0];
        FileReader reader = new FileReader();
        reader.onLoad.listen((ProgressEvent e) {
          qClient.sendArrayBuffer(otherId, reader.result);
        });

        reader.readAsArrayBuffer(f);
      });
    }

    if (e.state == InitializationState.REMOTE_READY) {

      qClient.joinChannel("abc");
    }
  });

  qClient.onSignalingOpenEvent.listen((SignalingOpenEvent e) {

    qClient.setChannelLimit(channelLimit);
  });



  qClient.onSignalingCloseEvent.listen((SignalingCloseEvent e) {
    new Timer(const Duration(milliseconds: 10000), () {
      qClient.initialize();
    });
  });

  qClient.onPacketEvent.listen((PacketEvent e) {
    print("packet ${e.type.toString()}");
    if (e.type.toString() == PacketType.ID.toString() || e.type.toString() == PacketType.JOIN.toString()) {
      print("assigning id ${e.packet.id}");
      otherId = e.packet.id;
    }
  });

  qClient.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
      output.nodes.clear();
      output.appendHtml("chunk ${bce.sequence} of ${bce.totalSequences} ${bce.bytes} ${bce.bytesLeft}<br>");

    } else if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
      output.nodes.clear();
      output.appendHtml("complete sequence ${bsce.sequence}<br>");
    } else if (e is BinaryBufferComplete) {
      BinaryBufferComplete bbc = e;
      output.appendHtml("Buffer complete ${bbc.buffer.byteLength}<br>");
    }
  });

  qClient.initialize();
}

