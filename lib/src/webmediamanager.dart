part of demo_client;

class WebMediaManager extends MediaManager {
  /* Static instance */
  static MediaManager _instance;

  /* Singleton logger */
  Logger log = new Logger();

  /* Default poster image for video */
  String _poster = "/static/img/access.png";

  /* List holding all the video containers */
  List<MediaContainer> _containers;

  /* The big video element */
  DivElement _mainHost;

  /* Smaller video elements */
  DivElement _childHost;

  LocalMediaStream _localStream;
  /**
   * Factory constructor
   */
  factory WebMediaManager() {
    if (_instance == null)
      _instance = new WebMediaManager._private();

    return _instance;
  }

  /**
   * Private constructor
   */
  WebMediaManager._private() {
    _containers = new List<MediaContainer>();
  }

  /**
   * Sets the main container where the big video element is shown
   * @param m String the id of the html element
   */
  void setMainContainer(String m) {
    _mainHost = query(m);
    log.Debug("Setting main container $m");
    log.Debug(_mainHost.id);
  }

  /**
   * Sets the child container where the smaller video elements are
   * @param c String the id of the html element
   */
  void setChildContainer(String c) {
    _childHost = query(c);
  }

  void setStream(MediaStream ms, MediaContainer vc) {
    vc.setStream(ms);
  }

  void addStream(MediaStream ms, String id, [bool main]) {
    MediaContainer vc;
    if (?main) {
      vc = addVideoContainer(id, "main");
    } else {
      vc = addVideoContainer(id);
    }
    vc.setStream(ms);
  }
  void addAudioStream(MediaStream ms, String id, [bool main]) {
    MediaContainer vc;
    if (?main) {
      vc = addAudioContainer(id, "main");
    } else {
      vc = addAudioContainer(id);
    }
    vc.setStream(ms);
  }
  void setLocalStream(MediaStream ms) {
    _localStream = ms;
  }

  MediaStream getLocalStream() {
    return _localStream;
  }

  /**
   * Adds a remote stream, creates elements.
   * @param ms MediaStream
   * @param id String the id of the user
   */
  void addRemoteStream(MediaStream ms, String id, [bool main]) {
    if (?main)
      addStream(ms, id, main);
    else
      addStream(ms, id);
  }

  void removeRemoteStream(String id) {
    MediaContainer vc = getMediaContainer(id);
    if (vc != null)
      removeMediaContainer(vc);
  }

  /**
   * Adds a videocontainer to the dom tree
   */
  MediaContainer addVideoContainer(String id, [String target]) {
    MediaContainer vc = createVideoContainer(id);
    MediaContainer main = getMainMediaContainer();

    DivElement host;

    if (main == null) {
      log.Debug("main is null, setting it to be the host");
      host = _mainHost;
    } else {
      log.Debug("host was not null, host id not child");
      host = _childHost;
      if (?target)
        host = _mainHost.id == target ? _mainHost : _childHost;
      if (host == _mainHost) {
        log.Debug("host is now main");
        moveMediaContainer(main, _childHost);
      }
    }

    _containers.add(vc);
    inject(host, vc, true);

    return vc;
  }

  /**
   * Adds a videocontainer to the dom tree
   */
  MediaContainer addAudioContainer(String id, [String target]) {
    MediaContainer vc = createAudioContainer(id);
    MediaContainer main = getMainMediaContainer();

    DivElement host;

    if (main == null) {
      log.Debug("main is null, setting it to be the host");
      host = _mainHost;
    } else {
      log.Debug("host was not null, host id not child");
      host = _childHost;
      if (?target)
        host = _mainHost.id == target ? _mainHost : _childHost;
      if (host == _mainHost) {
        log.Debug("host is now main");
        moveMediaContainer(main, _childHost);
      }
    }

    _containers.add(vc);
    inject(host, vc, true);

    return vc;
  }

  /**
   * Creates the videocontainer object
   */
  MediaContainer createVideoContainer(String id) {
    var v = new VideoContainer(this, id);
    v.matcher.onClick.listen(_onContainerClick);
    _containers.add(v);
    return v;
  }

  /**
   * Creates the audiocontainer object
   */
  MediaContainer createAudioContainer(String id) {
    var v = new AudioContainer(this, id);
    v.matcher.onClick.listen(_onContainerClick);
    _containers.add(v);
    return v;
  }

  void _onContainerClick(Event e) {
    MediaContainer vc = getContainerByMatcherElement(e.target);
    if (!isMain(vc)) {
      addNewMainContainer(vc);
    }
  }

  void addNewMainContainer(MediaContainer vc) {
    MediaContainer main = getMainMediaContainer();
    if (main != null)
      moveMediaContainer(main, _childHost);
    moveMediaContainer(vc, _mainHost);
  }
  /**
   * Removes videocontainer from it's curretn html parent node and sets it to a new one
   */
  void moveMediaContainer(MediaContainer vc, DivElement newHost) {
    log.Debug("Moving vc ${vc.id} to new host");
    vc.pause();
    vc.matcher.remove();
    inject(newHost, vc);
    setProportions(vc);
    vc.play();
  }

  /**
   * Adds the Element returned by video containers matcher getter to the domtree
   * optionally also calls the initialize method on video container
   */
  void inject(DivElement host, MediaContainer vc, [bool init]) {
    if (?init) {
      vc.initialize();
    }

    host.nodes.add(vc.matcher);
    host.style.visibility = "visible";
    if (host == _mainHost) {
      vc.matcher.classes.remove("auxvid");
    } else {
      vc.matcher.classes.add("auxvid");
    }

  }

  /**
   * Sets the video proportions based on aspect ratio
   * called after video container receives loadedmetadata event from the video element
   */
  void setProportions(VideoContainer vc) {
    log.Debug("setProportions: ${vc.id}");
    int width = isMain(vc) ? _mainHost.client.width : (_childHost.client.width ~/ 3) - 3;
    int height = Util.getHeight(width, vc.aspectRatio);
    log.Debug("Width: $width Height: $height");


    vc.video.style.width = "${width}px";
    vc.video.style.height = "${height}px";

  }

  DivElement getDivContainer(MediaContainer caller) {
    if (_containers.contains(caller))
      return _childHost;
    return _mainHost;
  }


  bool isMain(MediaContainer vc) {
    return vc.matcher.parent == _mainHost;
  }

  MediaContainer getContainerByMatcherElement(Element e) {
    for (int i = 0; i < _containers.length; i++) {
      MediaContainer vc = _containers[i];
      if (vc.matcher == e) {
        return vc;
      }
    }
    return null;
  }

  MediaContainer getContainerByParent(DivElement e) {
    log.Debug("Container size = ${_containers.length}");
    for (int i = 0; i < _containers.length; i++) {
      MediaContainer vc = _containers[i];
      log.Debug("----- ${e.id} ${vc.matcher.id}");
      if (vc.matcher.parent == e) {
        return vc;
      }
    }
    return null;
  }

  MediaContainer getMainMediaContainer() {
    return getContainerByParent(_mainHost);
  }

  MediaContainer getFirstChildContainer() {
    return getContainerByParent(_childHost);
  }

  MediaContainer getMediaContainer(String id) {
    for (int i = 0; i < _containers.length; i++) {
      MediaContainer vc = _containers[i];
      if (vc.id == id)
        return vc;
    }

    return null;
  }

  void removeMediaContainerById(String id) {

    MediaContainer vc = getMediaContainer(id);
    if (vc == null) {
      log.Warning("removeMediaContainerById: $id not found");
      return;
    }

    removeMediaContainer(vc);
  }

  void removeMediaContainer(MediaContainer vc) {
    bool wasMain = isMain(vc);
    _containers.removeAt(_containers.indexOf(vc));
    vc.destroy();
    vc = null;

    if (wasMain) {
      var v = getFirstChildContainer();
      if (v != null)
        moveMediaContainer(v, _mainHost);
    }

  }
}