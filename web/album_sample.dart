import "dart:html";
import "dart:async";
import 'dart:json' as json;

import '../lib/demo_client.dart';
//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

void main() {
  final String key = query("#key").text;
  DivElement album = query("#album");
  ProgressElement progress = query("#progress_bar");
  progress.style.width = "800px";
  progress.style.display = "none";

  AlbumCanvas ac = new AlbumCanvas(query("#albumcanvas"));
  Thumbnailer thumb = new Thumbnailer();
  List<String> peers = new List<String>();
  final int channelLimit = 10;

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
      ac.setImageFromBlob(bfce.blob).then((ImageElement img) {
        String dataUrl = thumb.render(img);
        ImageElement test = new ImageElement();
        test.onLoad.listen((Event e) {
          query("#controls").nodes.add(test);
        });
        test.src = dataUrl;

        new Timer(const Duration(milliseconds: 2000), () {
          progress.style.display = "none";
        });
      });
    }

    else if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
      if (progress.style.display == "none")
        progress.style.display = "block";
      progress.max = bce.totalSequences;
      progress.value = bce.sequence;
    }

    else if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
      print("Send complete");
    }

    else if (e is BinaryChunkWriteEvent) {
      BinaryChunkWriteEvent bcwrite = e;
      print("Writing chunk");
    }

    else if (e is BinaryChunkWroteEvent) {
      BinaryChunkWroteEvent bcwrote = e;
      print("Wrote chunk");
    }

  });

  FileUploadInputElement fuie = query("#file");
  FileReader reader = new FileReader();
  String currentFileName;
  fuie.onChange.listen((Event e) {
    for (int i = 0; i < fuie.files.length; i++) {
      File file = fuie.files[i];
      currentFileName = file.name;
      reader.readAsArrayBuffer(file);
    }
  });

  reader.onLoadEnd.listen((ProgressEvent e) {
    ArrayBuffer data = reader.result;
    print("read buffer");
    peers.forEach((String id) {
      client.sendArrayBufferReliable(id, new FileNamePacket(currentFileName).toBuffer()).then((int i) {
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

class Thumbnailer {
  CanvasElement _canvas;
  CanvasRenderingContext2D _ctx;

  int _canvasWidth = 300;
  int _canvasHeight = 200;
  set width(int w) => setCanvasWidth(w);
  set Height(int h) => _canvasHeight = h;
  CanvasElement get canvas => _canvas;

  Thumbnailer() {
    _canvas = new CanvasElement();
    _ctx = _canvas.context2d;
  }

  void setCanvasWidth(int w) {
    _canvas.width = w;
    _canvasWidth = w;
  }

  void setCanvasHeight(int h) {
    _canvas.height = h;
    _canvasHeight = h;
  }

  String render(ImageElement img) {
    _ctx.drawImageScaled(img, 0, 0, _canvasWidth, _canvasHeight);
    return _canvas.toDataUrl("image/png");
  }
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

  Future<ImageElement> setImageFromBuffer(ArrayBuffer buffer) {
    return _setImageFromUrl(Url.createObjectUrl(new Blob([new Uint8Array.fromBuffer(buffer)])));
  }

  Future<ImageElement> setImageFromBlob(Blob blob) {
    return _setImageFromUrl(Url.createObjectUrl(blob));
  }

  Future<ImageElement>_setImageFromUrl(String url) {
    Completer<ImageElement> completer = new Completer<ImageElement>();
    ImageElement img = new ImageElement();
    img.onLoad.listen((Event e) {
      _clear();
      if (img.height >= img.width) {
        _ctx.drawImageScaled(img, 0, 0, img.width * (_canvas.height/img.height), _canvas.height);
      } else {
        _ctx.drawImageScaled(img, 0, 0, _canvas.width, img.height * (_canvas.width/img.width));
      }
      Url.revokeObjectUrl(url);
      completer.complete(img);
    });
    img.src = url;
    return completer.future;
  }

  void _clear() {
    _ctx.clearRect(0, 0, _canvas.width, _canvas.height);
  }
}
