part of demo_client;

abstract class MediaContainer {
  const String CSS_HIDDEN = "hidden";
  const String CSS_VISIBLE = "visible";

  MediaManager _manager;
  MediaStream _mediaStream;
  MediaElement _media;
  String _id;
  String _url;

  set id(String value) => _id = value;
  String get id => _id;

  MediaContainer(MediaManager manager, String id) {
    _manager = manager;
    _id = id;
  }

  void destroy();
  void initialize();

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

  void setStream(MediaStream m) {
    _mediaStream = m;
    if (m is LocalMediaStream)
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
}