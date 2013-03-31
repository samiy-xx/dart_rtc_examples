import "dart:html";
import "dart:async";
import "dart:crypto";
import '../lib/demo_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

void main() {
  var key = query("#key").text;
  String otherId;
  String unreliableString = "This string is sent with fire and forget attitude";
  String reliableString = "This string is sent and expects a future to return bool";
  Timer t;

  ChannelClient client = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.CHANNEL_READY) {
      //client.setChannelLimit(channelLimit);
    }

    if (e.state == InitializationState.REMOTE_READY) {
      client.joinChannel(key);
    }
  });

  client.onSignalingCloseEvent.listen((SignalingCloseEvent e) {
    new Timer(const Duration(milliseconds: 10000), () {
      client.initialize();
    });
  });

  client.onDataChannelStateChangeEvent.listen((DataChannelStateChangedEvent e) {
    if (e.state == DATACHANNEL_OPEN) {
      // for canary, peer state change doesnt seem to fire on canary
      otherId = e.peerwrapper.id;
      bool reliable = true;
      int s = 1;
      t = new Timer.periodic(const Duration(milliseconds: 1000), (Timer t) {
        String toSend = " ${reliable ? reliableString : unreliableString} sequence = $s";
        client.sendArrayBuffer(otherId, BinaryData.bufferFromString(toSend)).then((int rtt) {
          insertString("Sent buffer reliable = $reliable sequence = $s milliseconds $rtt");
        });
        s++;
        reliable = !reliable;
      });
    }
    if (e.state == DATACHANNEL_CLOSED) {
      if (t != null) {
        t.cancel();
        t = null;
      }
    }
  });

  client.onPeerStateChangeEvent.listen((PeerStateChangedEvent e) {
    new Logger().Debug("Peer state changed to ${e.state}");
    if (e.state == PEER_STABLE) {
      new Logger().Debug("Peer state changed to stable");
      otherId = e.peerwrapper.id;
    }
  });

  client.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
    }

    else if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
    }

    else if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
      insertString("RECV: ${BinaryData.stringFromBuffer(e.buffer)}");
    }

    else if (e is BinaryPeerPacketEvent) {
      BinaryPeerPacketEvent bppe = e;
    }
  });
  client.initialize();
}

void insertString(String s) {
  DivElement element = query("#application");
  element.appendHtml("$s <br/>");
}

