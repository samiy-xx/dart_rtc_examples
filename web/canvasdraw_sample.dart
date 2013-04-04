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
  final int channelLimit = 10;



  ChannelClient client = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  CanvasDraw draw = new CanvasDraw(query("#drawcanvas"), client);

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
      draw.addPeer(e.peerwrapper);
    } else if (e.state == DATACHANNEL_CLOSED) {
      draw.removePeer(e.peerwrapper);
    }
  });

  client.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;

      Map m = json.parse(BinaryData.stringFromBuffer(e.buffer));
      if (m.containsKey('packetType')) {
        int packetType = m['packetType'];
        if (packetType == PeerPacket.TYPE_START_DRAW) {
          draw.startDraw(e.peer, StartDrawPacket.fromMap(m));
        } else if (packetType == PeerPacket.TYPE_UPDATE_DRAW) {
          draw.updateDraw(e.peer, UpdateDrawPacket.fromMap(m));
        } else if (packetType == PeerPacket.TYPE_END_DRAW) {
          draw.endDraw(e.peer, EndDrawPacket.fromMap(m));
        }
      }
    }
  });

  client.initialize();
}

class CanvasDraw {
  CanvasElement _element;
  CanvasRenderingContext2D _ctx;
  List<DataPeerWrapper> _peerIds;
  PeerPacket _toSend;
  ChannelClient _client;
  Timer _timer;
  const int _updateInterval = 30;
  int _lastSent;
  bool _isMouseDown = false;

  CanvasDraw(CanvasElement c, ChannelClient client) {
    _element = c;
    _element.width = 770;
    _element.height = 400;
    _ctx = c.context2d;
    _peerIds = new List<DataPeerWrapper>();

    _client = client;
    _lastSent = new DateTime.now().millisecondsSinceEpoch;
    //_timer = new Timer.periodic(const Duration(milliseconds: updateInterval), _onTick);
    _element.onMouseDown.listen(_onMouseDown);
    _element.onMouseMove.listen(_onMouseMove);
    _element.onMouseUp.listen(_onMouseUp);
    _element.onTouchStart(_onTouchStart);
  }

  void addPeer(DataPeerWrapper wrapper) {
    if (!_peerIds.contains(wrapper))
      _peerIds.add(wrapper);
  }

  void removePeer(DataPeerWrapper wrapper) {
    _peerIds.remove(wrapper);
  }

  void startDraw(DataPeerWrapper dpw, StartDrawPacket p) {

    _ctx.beginPath();
    _ctx.moveTo(p.x, p.y);
  }

  void updateDraw(DataPeerWrapper dpw, UpdateDrawPacket p) {

    _ctx.lineTo(p.x, p.y);
    _ctx.stroke();
  }

  void endDraw(DataPeerWrapper dpw, EndDrawPacket p) {

    _ctx.lineTo(p.x, p.y);
    _ctx.stroke();
  }

  void _onTouchStart(TouchEvent e) {

  }

  void _onMouseDown(MouseEvent e) {
    _isMouseDown = true;

    _ctx.beginPath();
    _ctx.moveTo(e.offset.x, e.offset.y);

    _toSend = new StartDrawPacket(e.offset.x, e.offset.y);
    for (int i = 0; i < _peerIds.length; i++) {
      PeerWrapper pw = _peerIds[i];
      _client.sendArrayBufferReliable(pw.id, _toSend.toBuffer());
    }
  }

  void _onMouseUp(MouseEvent e) {
    _isMouseDown = false;

    _ctx.lineTo(e.offset.x, e.offset.y);
    _ctx.stroke();

    _toSend = new EndDrawPacket(e.offset.x, e.offset.y);
    for (int i = 0; i < _peerIds.length; i++) {
      PeerWrapper pw = _peerIds[i];
      _client.sendArrayBufferReliable(pw.id, _toSend.toBuffer());
    }
  }

  void _onMouseMove(MouseEvent e) {
    if (!_isMouseDown)
      return;

    _ctx.lineTo(e.offset.x, e.offset.y);
    _ctx.stroke();

    int now = new DateTime.now().millisecondsSinceEpoch;
    if (now > _lastSent + _updateInterval) {
      _toSend = new UpdateDrawPacket(e.offset.x, e.offset.y);
      for (int i = 0; i < _peerIds.length; i++) {
        PeerWrapper pw = _peerIds[i];
        _client.sendArrayBufferReliable(pw.id, _toSend.toBuffer());
      }
      _lastSent = now;
    }
  }

  void _onTick(Timer t) {

  }
}

