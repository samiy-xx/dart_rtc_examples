import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';

import '../../dart_rtc_client/lib/rtc_client.dart';

void main() {
  int channelLimit = 5;
  Element c = query("#container");
  Notifier notifier = new Notifier();
  WebVideoContainer vc = vm.addVideoContainer("main_user", "main");

  ChannelClient client = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(true)
  .setRequireVideo(false)
  .setRequireDataChannel(false)
  .setAutoCreatePeer(true);

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {

    if (e.state == InitializationState.CHANNEL_READY) {
      if (!client.setChannelLimit(channelLimit)) {
        notifier.display("Failed to set new channel user limit");
      }
    }

    if (e.state == InitializationState.REMOTE_READY) {
      notifier.display("Joining channel abc");
      client.joinChannel("abc");
    }
  });

  client.onSignalingOpenEvent.listen((SignalingOpenEvent e) {
    notifier.display("Signaling connected to server ${e.message}");
  });

  client.onRemoteMediaStreamAvailableEvent.listen((MediaStreamAvailableEvent e) {
    if (e.isLocal) {
      vm.setLocalStream(e.stream);
      vc.setStream(e.stream);
    } else {
      vm.addStream(e.stream, e.peerWrapper.id);
    }
  });

  client.onRemoteMediaStreamRemovedEvent.listen((MediaStreamRemovedEvent e) {
    notifier.display("Remote stream removed");
    vm.removeRemoteStream(e.pw.id);
  });

  client.onSignalingCloseEvent.listen((SignalingCloseEvent e) {
    notifier.display("Signaling connection to server has closed (${e.message})");

    new Timer(const Duration(milliseconds: 10000), () {
      notifier.display("Attempting to reconnect to server");
      client.initialize();
    });
  });

  client.initialize();
}