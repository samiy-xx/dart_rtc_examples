part of demo_client;

class WebVideoManager extends MediaManager {
  Element _hostContainer;
  Element _auxiliaryVideos;
  List<VideoContainer> _mediaContainers;

  WebVideoManager() {
    _mediaContainers = new List<VideoContainer>();
    _hostContainer = _createHostContainer();
    _auxiliaryVideos = query("#auxvideos");
    _setContainerDimensions(window.innerWidth, window.innerHeight);
    window.onResize.listen(_onWindowResize);
    window.onDeviceOrientation.listen(_onOrientationChange);
  }

  void setContainer(Element element) {
    _hostContainer = element;
  }

  VideoContainer addVideoContainer(String id) {
    VideoContainer vc = new VideoContainer(this, id);
    //vc.width = _hostContainer.client
    //vc.mediaElement.style.width = cssify(_hostContainer.client.width);
    //vc.mediaElement.style.height = cssify(_hostContainer.client.height);

    if (_mediaContainers.length == 0) {
      vc.isMain = true;
      _addMainContainer(vc);
    } else {
      _addAuxContainer(vc);
    }
    return vc;
  }

  void removeVideoContainer(String id) {
    VideoContainer mc = getVideoContainer(id);
    if (mc != null) {
      window.setImmediate(() {
        mc.detach();
        _mediaContainers.remove(mc);
        if (mc.isMain && _mediaContainers.length > 0) {
          VideoContainer vc = _mediaContainers.first;
          vc.isMain = true;
          vc.detach();
          _addMainContainer(vc);
          new Timer(const Duration(milliseconds : 100), () {
            vc.play();
          });
        }
      });
    }
  }

  VideoContainer getVideoContainer(String id) {
    var c = _mediaContainers.where((MediaContainer mc) => mc.id == id);
    if (c.length == 0)
      return null;
    return c.first;
  }

  void _addMainContainer(VideoContainer mc) {
    window.setImmediate(() {
      _hostContainer.append(mc.mediaElement);
      _mediaContainers.add(mc);
      _maximizeMainVideo();
    });
  }

  void _addAuxContainer(VideoContainer mc) {
    VideoElement ve = mc.mediaElement;
    ve.onClick.listen((MouseEvent e) {
      var m = _getMainContainer();
      //m.pause();
      m.isMain = false;
      m.detach();
      _addAuxContainer(m);
      _setAuxVideoDimensions(m, 100, 80);
      m.play();

      var c = _getContainerByElement(e.target);
      //c.pause();
      c.detach();
      _addMainContainer(c);
      _maximizeMainVideo();
      c.play();

      new Timer(const Duration(milliseconds : 100), () {
        c.play();
      });
      c.isMain = true;
    });
    window.setImmediate(() {
      _auxiliaryVideos.append(mc.mediaElement);
      _mediaContainers.add(mc);
      _setAuxVideoDimensions(mc, 100, 80);
    });
  }

  Element _createHostContainer() {
    DivElement div = new DivElement();
    div.id="host_container";
    div.style.height = "100%";

    document.body.append(div);
    return div;
  }

  VideoContainer _getContainerByElement(Element e) {
    var c = _mediaContainers.where((VideoContainer mc) => mc.mediaElement == e);
    if (c.length == 0)
      return null;
    return c.first;
  }

  VideoContainer _getMainContainer() {
    var c = _mediaContainers.where((VideoContainer mc) => mc.isMain);
    if (c.length == 0)
      return null;
    return c.first;
  }

  MediaStream _getLocalStream() {
    var c = _mediaContainers.where((VideoContainer mc) => mc.isLocal);
    if (c.length == 0)
      return null;
    return c.first.mediaStream;
  }

  void _onWindowResize(Event e) {
    _setContainerDimensions(window.innerWidth, window.innerHeight);
    _maximizeMainVideo();
    _mediaContainers.where((VideoContainer mc) => !mc.isMain).forEach((VideoContainer mc) => _setAuxVideoDimensions(mc, 100, 80));
  }

  void _onOrientationChange(DeviceOrientationEvent e) {
    _setContainerDimensions(window.innerWidth, window.innerHeight);
    _maximizeMainVideo();
    _mediaContainers.where((VideoContainer mc) => !mc.isMain).forEach((VideoContainer mc) => _setAuxVideoDimensions(mc, 100, 80));
  }

  void _setContainerDimensions(int width, int height) {
    String w = cssify(width);
    String h = cssify(height);
    _hostContainer.style.width = w;
    _hostContainer.style.height = h;
  }

  void _setAuxVideoDimensions(VideoContainer vc, int width, int height) {
    vc.width = width;
    vc.height = height;
  }

  void _maximizeMainVideo() {
    var main = _getMainContainer();
    if (main == null)
      return;

    main.width = window.innerWidth;
    main.height = window.innerHeight;
  }
}
