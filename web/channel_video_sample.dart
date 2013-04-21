import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';


//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
//import '../../dart_rtc_common/lib/rtc_common.dart';

import '../../dart_rtc_client/lib/rtc_client.dart';

void main() {
  var key = query("#key").text;
  int channelLimit = 5;
  Element c = query("#container");
  Notifier notifier = new Notifier();
  WebVideoManager vm = new WebVideoManager();
  //vm.setMainContainer("#wrapper");
  //vm.setChildContainer("#aux");
  //vm.setContainer(query("#main"));
  //VideoContainer vc = vm.addVideoContainer("main_user", "main");
  VideoContainer vc = vm.addVideoContainer("main");
  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  //.setChannel("abc")
  .setRequireAudio(true)
  .setRequireVideo(true)
  .setRequireDataChannel(false)
  .setAutoCreatePeer(true);

  qClient.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {

    if (e.state == InitializationState.CHANNEL_READY) {
      if (!qClient.setChannelLimit(channelLimit)) {
        notifier.display("Failed to set new channel user limit");
      }
    }

    if (e.state == InitializationState.REMOTE_READY) {
      notifier.display("Joining channel $key");
      qClient.joinChannel(key);
    }
  });

  qClient.onRemoteMediaStreamAvailableEvent.listen((MediaStreamAvailableEvent e) {
    if (e.isLocal) {
      vm.getVideoContainer("main").setStream(e.stream);
    } else {
      VideoContainer vc = vm.addVideoContainer(e.peerWrapper.id);
      vc.setStream(e.stream);
    }

  });

  qClient.onRemoteMediaStreamRemovedEvent.listen((MediaStreamRemovedEvent e) {
    notifier.display("Remote stream removed");
    vm.removeVideoContainer(e.pw.id);
  });

  qClient.onSignalingStateChanged.listen((SignalingStateEvent e) {
    if (e.state == Signaler.SIGNALING_STATE_OPEN) {
      notifier.display("Signaling connected to server");
      qClient.setChannelLimit(channelLimit);
    } else if (e.state == Signaler.SIGNALING_STATE_CLOSED) {
      new Timer(const Duration(milliseconds: 10000), () {
        notifier.display("Attempting to reconnect to server");
        qClient.initialize();
      });
    }
  });

  qClient.initialize();
}

