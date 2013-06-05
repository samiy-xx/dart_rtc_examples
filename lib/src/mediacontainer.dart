part of demo_client;

abstract class MediaContainer {
  const String CSS_HIDDEN = "hidden";
  const String CSS_VISIBLE = "visible";

  MediaManager _manager;
  MediaStream _mediaStream;
  MediaElement _media;
  String _id;
  String _url;
  bool _isMain;

  set id(String value) => _id = value;
  set isMain(bool value) => _isMain = value;
  String get id => _id;
  bool get isLocal => isLocalStream();
  bool get isMain => _isMain;
  MediaStream get mediaStream => _mediaStream;
  MediaElement get mediaElement => _media;
  set width(int w) => setWidth(w);
  set height(int h) => setHeight(h);
  MediaContainer(MediaManager manager, String id) {
    _manager = manager;
    _id = id;
    _isMain = false;
  }

  void destroy();
  void initialize();

  bool isLocalStream() {
    return _mediaStream != null && _mediaStream is MediaStream;
  }

  void play() {
    _media.play();
  }

  void pause() {
    _media.pause();
  }

  void mute() {
    _media.muted = true;
  }

  void unmute() {
    _media.muted = false;
  }

  void detach() {
    _media.remove();
  }

  void setWidth(int w) {
    _media.style.width = _cssify(w);
  }

  void setHeight(int h) {
    _media.style.height = _cssify(h);
  }

  void setStream(MediaStream m) {
    _mediaStream = m;
    if (m is MediaStream)
      mute();

    setUrl(Url.createObjectUrl(m));
  }

  void setUrl(String url) {
    _media.src = url;
    _url = url;
  }

  void muteVideoTracks() {
    if (_mediaStream.getVideoTracks().length == 0)
      return;

    _mediaStream.getVideoTracks().forEach((MediaStreamTrack mst) {
      mst.enabled = false;
    });
  }

  void unMuteVideoTracks() {
    if (_mediaStream.getVideoTracks().length == 0)
      return;

    _mediaStream.getVideoTracks().forEach((MediaStreamTrack mst) {
      mst.enabled = true;
    });
  }

  void muteAudioTracks() {
    if (_mediaStream.getAudioTracks().length == 0)
      return;

    _mediaStream.getAudioTracks().forEach((MediaStreamTrack mst) {
      mst.enabled = false;
    });
  }

  void unMuteAudioTracks() {
    if (_mediaStream.getAudioTracks().length == 0)
      return;

    _mediaStream.getAudioTracks().forEach((MediaStreamTrack mst) {
      mst.enabled = true;
    });
  }

  String _cssify(int m) {
    return m.toString() + "px";
  }
}