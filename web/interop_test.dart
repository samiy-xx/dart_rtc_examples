import "dart:html";
import "dart:async";
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import '../lib/demo_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';


void main() {
  setLogging();
  VideoElement local = query("#local_video");
  VideoElement remote = query("#remote_video");
  FileUploadInputElement fuie = query("#upload");
  PeerConnection pc;

  PeerClient client = new PeerClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(true)
  .setRequireVideo(true)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  fuie.onChange.listen((Event e) {
    client.sendFile(pc.id, fuie.files[0]);
  });

  client.onDataChannelStateChangeEvent.listen((DataChannelStateChangedEvent e) {
    if (e.state == "open") {
      print("Datachannel open");
      pc = e.peerwrapper;
    }
  });

  client.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
    }

    else if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
      print("GOT FILE");
    }

    else if (e is BinaryFileCompleteEvent) {
      print("File complete");
    }
  });

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.CHANNEL_READY) {

    }

    if (e.state == InitializationState.REMOTE_READY) {
      client.joinChannel("abc");
    }
  });

  client.onRemoteMediaStreamAvailableEvent.listen((MediaStreamAvailableEvent e) {
    if (e.isLocal) {
      local.src = Url.createObjectUrl(e.stream);
    } else {
      remote.src = Url.createObjectUrl(e.stream);
    }
  });

  client.onRemoteMediaStreamRemovedEvent.listen((MediaStreamRemovedEvent e) {
    remote.pause();
  });

  client.onSignalingStateChanged.listen((SignalingStateEvent e) {
    if (e.state == Signaler.SIGNALING_STATE_CLOSED) {
      new Timer(const Duration(milliseconds: 10000), () {
        client.initialize();
      });
    }
  });

  client.initialize();
}

void setLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.OFF;

  var pr = new PrintHandler();
  Logger.root.onRecord.listen((LogRecord lr) {
    pr.call(lr);
  });
  new Logger("dart_rtc_client.PeerConnection")..level = Level.ALL;
  new Logger("dart_rtc_client.PeerClient")..level = Level.ALL;
  new Logger("dart_rtc_client.SignalHandler")..level = Level.ALL;
  new Logger("dart_rtc_client.UDPDataWriter")..level = Level.ALL;
  new Logger("dart_rtc_client.UDPDataReader")..level = Level.ALL;
  new Logger("dart_rtc_client.TCPDataWriter")..level = Level.ALL;
  new Logger("dart_rtc_client.TCPDataReader")..level = Level.ALL;
}