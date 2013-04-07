import "dart:html";
import "dart:async";
import 'dart:json' as json;

import '../lib/demo_client.dart';
import 'package:dart_rtc_common/rtc_common.dart';
import 'package:dart_rtc_client/rtc_client.dart';

void main() {
  final String key = query("#key").text;
  DivElement album = query("#album");
  ProgressElement progress = query("#progress_bar");
  progress.style.width = "800px";
  progress.style.display = "none";

  AlbumCanvas ac = new AlbumCanvas(query("#albumcanvas"));
  List<String> peers = new List<String>();
  final int channelLimit = 2;

  ChannelClient client = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.CHANNEL_READY) {
      client.setChannelLimit(channelLimit);
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
      if (!peers.contains(e.peerwrapper.id))
        peers.add(e.peerwrapper.id);
    } else if (e.state == DATACHANNEL_CLOSED) {
      window.setImmediate(() {
        if (peers.contains(e.peerwrapper.id))
          peers.remove(e.peerwrapper.id);
      });
    }
  });

  client.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
    }

    else if (e is BinaryFileCompleteEvent) {
      BinaryFileCompleteEvent bfce = e;
      ac.setImageFromBlob(bfce.blob);
      new Timer(const Duration(milliseconds: 2000), () {
        progress.style.display = "none";
      });
    }

    else if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
      if (progress.style.display == "none")
        progress.style.display = "block";
      progress.max = bce.totalSequences;
      progress.value = bce.sequence;
    }
  });

  FileUploadInputElement fuie = query("#file");
  FileReader reader = new FileReader();
  fuie.onChange.listen((Event e) {
    for (int i = 0; i < fuie.files.length; i++) {
      File file = fuie.files[i];
      reader.readAsArrayBuffer(file);
    }
  });

  reader.onLoadEnd.listen((ProgressEvent e) {
    ArrayBuffer data = reader.result;
    print("read buffer");
    peers.forEach((String id) {
      client.sendArrayBufferReliable(id, new FileNamePacket("blob").toBuffer()).then((int i) {
        client.sendFile(id, data).then((int i) {
          int seconds = i > 0 ? i ~/ 1000 : 0;
          print("Sent image to id $id in $seconds seconds");
        });
      });
    });
    ac.setImageFromBuffer(data);
  });

  client.initialize();
}


class AlbumCanvas {
  const int CANVAS_WIDTH = 800;
  const int CANVAS_HEIGHT = 500;
  CanvasElement _canvas;
  CanvasRenderingContext2D _ctx;

  AlbumCanvas(CanvasElement c) {
    _canvas = c;
    _ctx = c.context2d;
    _canvas.height = CANVAS_HEIGHT;
    _canvas.width = CANVAS_WIDTH;
  }

  setImageFromBuffer(ArrayBuffer buffer) {
    _setImageFromUrl(Url.createObjectUrl(new Blob([new Uint8Array.fromBuffer(buffer)])));
  }

  setImageFromBlob(Blob blob) {
    _setImageFromUrl(Url.createObjectUrl(blob));
  }

  void _setImageFromUrl(String url) {
    ImageElement img = new ImageElement();
    img.onLoad.listen((Event e) {
      _clear();
      if (img.height >= img.width) {
        _ctx.drawImageScaled(img, 0, 0, img.width * (_canvas.height/img.height), _canvas.height);
      } else {
        _ctx.drawImageScaled(img, 0, 0, _canvas.width, img.height * (_canvas.width/img.width));
      }
      Url.revokeObjectUrl(url);
    });
    img.src = url;
  }

  void _clear() {
    _ctx.clearRect(0, 0, _canvas.width, _canvas.height);
  }
}
