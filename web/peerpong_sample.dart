import "dart:html";
import "dart:async";
import 'dart:json' as json;
import 'dart:math';
import '../lib/demo_client.dart';
import 'package:box2d/box2d_browser.dart';
//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

void main() {
  final String key = query("#key").text;
  final int channelLimit = 2;

  ChannelClient client = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);

  PeerPong pong = new PeerPong(query("#drawcanvas"), client);

  client.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.CHANNEL_READY) {
      client.setChannelLimit(channelLimit);
      if (e is ChannelInitializationStateEvent) {
        ChannelInitializationStateEvent cise = e;
        pong.setChannelData(cise.channel, cise.owner);
      }
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
      pong.setOtherId(e.peerwrapper.id);
      //draw.addPeer(e.peerwrapper.id);
    } else if (e.state == DATACHANNEL_CLOSED) {
      pong.removeOtherId();
      //draw.removePeer(e.peerwrapper.id);
    }
  });

  client.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;

      Map m = json.parse(BinaryData.stringFromBuffer(bbc.buffer));
      if (m.containsKey('packetType')) {
        int packetType = m['packetType'];
        if (packetType == PeerPacket.TYPE_CREATE_BALL) {
          pong.receiveCreateBall();
        } else if (packetType == PeerPacket.TYPE_UPDATE_PADDLE) {
          pong.setRemotePaddle(UpdatePaddlePacket.fromMap(m).y);
        } else if (packetType == PeerPacket.TYPE_UPDATE_VELOCITY) {
          UpdateVelocityPacket p = UpdateVelocityPacket.fromMap(m);
          pong.receiveVelocityUpdate(p.x, p.y);
        }
      }
    }
  });

  client.initialize();
}

abstract class Game {
  
}

class PeerPong extends Game {
  const int CANVAS_WIDTH = 800;
  const int CANVAS_HEIGHT = 500;
  const int VIEWPORT_SCALE = 10;
  final vec2 GRAVITY = new vec2(0.0, 0.0);
  const num TIME_STEP = 1/60;
  const int VELOCITY_ITERATIONS = 10;
  const int POSITION_ITERATIONS = 10;
  final int GAME_STATE_PAUSE = 0;
  final int GAME_STATE_PLAY = 1;
  int _currentGameState;
  ChannelClient _client;
  CanvasElement _canvas;  
  CanvasRenderingContext2D _ctx;  
  ViewportTransform _viewport;
  DebugDraw _debugDraw;
  World _world;
  List<Body> _bodies;
  Body _localPaddle;
  Body _remotePaddle;
  Body _leftPaddle;
  Body _rightPaddle;
  Body _ball;
  Body _leftWall;
  Body _rightWall;
  String _channel;
  bool _hosting = true;
  int _lastUpdate;
  String _otherId;
  PongContactListener _contact;
  
  PeerPong(CanvasElement c, ChannelClient client) {
    _currentGameState = GAME_STATE_PAUSE;
    _canvas = c;
    _ctx = c.context2d;
    _client = client;
    _canvas.width = CANVAS_WIDTH;
    _canvas.height = CANVAS_HEIGHT;
    _canvas.onMouseMove.listen(_onMouseMove);
    _canvas.onMouseDown.listen(_onMouseDown);
    _world = new World(GRAVITY, true, new DefaultWorldPool());
    vec2 extents = new vec2(CANVAS_WIDTH, CANVAS_HEIGHT);
    _viewport = new CanvasViewportTransform(extents, extents);
    _viewport.scale = VIEWPORT_SCALE;
    _debugDraw = new CanvasDraw(_viewport, _ctx);
    _world.debugDraw = _debugDraw;
    _contact = new PongContactListener();
    
    _world.contactListener = _contact;
    _bodies = new List<Body>();
    _lastUpdate = new DateTime.now().millisecondsSinceEpoch;
    runLoop();
    setupSomething();
  }
  
  int randomDirection() {
    int r = new Random().nextInt(1);
    return r == 0 ? -60 : 60;
  }
  
  void setOtherId(String id) {
    _otherId = id;
  }
  void removeOtherId() {
    _otherId = null;
  }
  
  void setChannelData(String channel, bool hosting) {
    _channel = channel;
    _hosting = hosting;
    
    if (hosting) {
      _localPaddle = _leftPaddle;
      _remotePaddle = _rightPaddle;
      
      _contact.onBeginContact = (Contact c) {
        
      };
      
      _contact.onEndContact = (Contact c) {
        _signalVelocityChange(_ball.linearVelocity);
      };
      
    } else {
      _localPaddle = _rightPaddle;
      _remotePaddle = _leftPaddle;
    }
  }
  
  void receiveCreateBall() {
    _ball = createBall();
  }
  
  void receiveVelocityUpdate(double x, double y) {
    print("Received velocity update");
    vec2 v = new vec2(x, y);
    _ball.linearVelocity = v;
  }
  
  void _onMouseDown(MouseEvent e) {
    if (_currentGameState == GAME_STATE_PAUSE) {
      int dir = randomDirection();
      _ball = createBall();
      _signalCreateBall().then((int i) {
        vec2 v = new vec2(dir, 10);
        _signalVelocityChange(v);
        _ball.linearVelocity = v;
      });
      _currentGameState = GAME_STATE_PLAY;
    }
  }
  
  Future<int> _signalCreateBall() {
    if (_otherId == null)
      return new Future.immediate(0);
    
    return _client.sendArrayBufferReliable(_otherId, new CreateBallPacket().toBuffer());
  }
  
  _signalVelocityChange(vec2 v) {
    if (_otherId == null)
      return;
    
    _client.sendArrayBufferReliable(_otherId, new UpdateVelocityPacket(v.x, v.y).toBuffer());
  }
  
  void _onMouseMove(MouseEvent e) {
    if (_localPaddle == null)
      return;
    
    double y = (CANVAS_HEIGHT - e.offset.y).toDouble() / VIEWPORT_SCALE;
    
    //_localPaddle.position.y = y;
    _localPaddle.setTransform(new vec2(_localPaddle.position.x, y), _localPaddle.angle);
    int now = new DateTime.now().millisecondsSinceEpoch;
    if (now > _lastUpdate + 50) {
      _signalMouseMove(y);
      _lastUpdate = now;
    }
  }
  
  void setRemotePaddle(double y) {
    _remotePaddle.position.y = y;
  }
  
  void _signalMouseMove(double y) {
    if (_otherId == null)
      return;
    
    _client.sendArrayBufferUnReliable(_otherId, new UpdatePaddlePacket(y).toBuffer());
  }
  
  void step(double t) {
    _world.step(TIME_STEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
    _ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    _world.drawDebugData();
    
    window.requestAnimationFrame((num time) { step(time); });
  }
  
  void runLoop() {
    window.requestAnimationFrame((num time) { 
      step(time);
    });
  }
  
  void setupSomething() {
    createTopWall();
    createBottomWall();
    createLeftWall();
    createRightWall();
    _leftPaddle = createLocalPaddle();
    _rightPaddle = createRemotePaddle();
    
  }
  
  void setListener() {
    
  }
  
  Body createBall() {
    // Create a bouncing ball.
    final bouncingCircle = new CircleShape();
    bouncingCircle.radius = 10 / VIEWPORT_SCALE;

    // Create fixture for that ball shape.
    final activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 1;
    activeFixtureDef.density =  0.05;
    activeFixtureDef.shape = bouncingCircle;

    // Create the active ball body.
    final activeBodyDef = new BodyDef();
    //activeBodyDef.linearVelocity = new vec2(14, -20);
    activeBodyDef.position = new vec2(-40, 25);
    activeBodyDef.type = BodyType.DYNAMIC;
    activeBodyDef.bullet = true;
    final activeBody = _world.createBody(activeBodyDef);
    _bodies.add(activeBody);
    activeBody.createFixture(activeFixtureDef);
    
    return activeBody;
  }
  
  void createTopWall() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(400.0 / VIEWPORT_SCALE, 10.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.friction = 0.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(-400.0 / VIEWPORT_SCALE, 500.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    _bodies.add(body);
  }
  
  void createBottomWall() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(400.0 / VIEWPORT_SCALE, 10.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.friction = 0.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(-400.0 / VIEWPORT_SCALE, 0.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    _bodies.add(body);
  }
  
  void createLeftWall() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(10.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.friction = 0.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(-800.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    _bodies.add(body);
  }
  
  void createRightWall() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(10.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.friction = 0.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(0.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    _bodies.add(body);
  }
  
  Body createLocalPaddle() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(5.0 / VIEWPORT_SCALE, 50.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.density = 5.0;
    fd.friction = 1;
    fd.restitution = 1.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(- 750.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    
    _bodies.add(body);
    
    return body;
  }
  
  Body createRemotePaddle() {
    FixtureDef fd = new FixtureDef();
    PolygonShape sd = new PolygonShape();
    sd.setAsBox(5.0 / VIEWPORT_SCALE, 50.0 / VIEWPORT_SCALE);
    fd.shape = sd;
    fd.density = 5.0;
    fd.friction = 1;
    fd.restitution = 1.0;
    BodyDef bd = new BodyDef();
    bd.position = new vec2(- 50.0 / VIEWPORT_SCALE, 250.0 / VIEWPORT_SCALE);
    final body = _world.createBody(bd);
    body.createFixture(fd);
    _bodies.add(body);
    
    return body;
  }
}

class PongContactListener implements ContactListener {
  Function _onBeginContact;
  Function _onEndContact;
  
  set onBeginContact(Function c) => _onBeginContact = c;
  set onEndContact(Function c) => _onEndContact = c;
  
  void beginContact(Contact contact) {
    print("beginContact");
    if (_onBeginContact != null)
      _onBeginContact(contact);
  }
  
  void endContact(Contact contact) {
    print("endContact");
    if (_onEndContact != null)
      _onEndContact(contact);
  }
  
  void preSolve(Contact contact, Manifold oldManifold) {
    
  }
  
  void postSolve(Contact contact, ContactImpulse impulse) {
    
  }
}

