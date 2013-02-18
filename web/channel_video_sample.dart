import "dart:html";
import '../lib/demo_client.dart';

import 'package:dart_rtc_common/rtc_common.dart';
import 'package:dart_rtc_client/rtc_client.dart';


void main() {
  int channelLimit = 5;
  Element c = query("#container");
  Notifier notifier = new Notifier();
  WebVideoManager vm = new WebVideoManager();
  vm.setMainContainer("#main");
  vm.setChildContainer("#aux");
  WebVideoContainer vc = vm.addVideoContainer("main_user", "main");

  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setChannel("abc")
  .setRequireAudio(true)
  .setRequireVideo(true)
  .setRequireDataChannel(false);


  qClient.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {

    if (e.state == InitializationState.CHANNEL_READY) {
      if (!qClient.setChannelLimit(channelLimit)) {
        notifier.display("Failed to set new channel user limit");
      }
    }
    if (e.state == InitializationState.REMOTE_READY) {
      qClient.joinChannel("abc");
    }
  });

  qClient.onSignalingOpenEvent.listen((SignalingOpenEvent e) {
    notifier.display("Signaling connected to server ${e.message}");
    qClient.setChannelLimit(channelLimit);
  });

  qClient.onRemoteMediaStreamAvailableEvent.listen((MediaStreamAvailableEvent e) {
    if (e.isLocal) {
      vm.setLocalStream(e.stream);
      vc.setStream(e.stream);
    } else {
      vm.addStream(e.stream, e.peerWrapper.id);
    }
  });

  qClient.onRemoteMediaStreamRemovedEvent.listen((MediaStreamRemovedEvent e) {
    notifier.display("Remote stream removed");
    vm.removeRemoteStream(e.pw.id);
  });

  qClient.onSignalingCloseEvent.listen((SignalingCloseEvent e) {
    notifier.display("Signaling connection to server has closed (${e.message})");
    window.setTimeout(() {
      notifier.display("Attempting to reconnect to server");
      qClient.initialize();
    }, 10000);
  });

  qClient.initialize();
}

