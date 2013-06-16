import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';

import '../../dart_rtc_client/lib/rtc_client.dart';

void main() {
  var key = query("#key").text;
  int channelLimit = 5;
  Notifier notifier = new Notifier();
  AudioElement localAudio = query("#local_audio");
  AudioElement remoteAudio = query("#remote_audio");

  PeerClient client = new PeerClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(true)
  .setAutoCreatePeer(true);

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.REMOTE_READY) {
      notifier.display("Joining channel $key");
      client.joinChannel(key);
    }
  });

  client.onMediaStreamAvailableEvent.listen((MediaStreamAvailableEvent e) {
    if (e.isLocal) {
      notifier.display("Got local stream, setting source to #local_audio");
      localAudio.src = Url.createObjectUrl(e.stream);
      localAudio.muted = true;
    } else {
      notifier.display("Got remote stream, setting source to #remote_audio");
      remoteAudio.src = Url.createObjectUrl(e.stream);
    }
  });

  client.onMediaStreamRemovedEvent.listen((MediaStreamRemovedEvent e) {
    notifier.display("Remote stream removed");
    remoteAudio.pause();
  });

  client.onSignalingStateChanged.listen((SignalingStateEvent e) {
    if (e.state == Signaler.SIGNALING_STATE_OPEN) {
      client.setChannelLimit(channelLimit);
    } else if (e.state == Signaler.SIGNALING_STATE_CLOSED){
      notifier.display("Signaling connection to server has closed");
      new Timer(const Duration(milliseconds: 10000), () {
        client.initialize();
      });
    }
  });

  client.initialize();
}