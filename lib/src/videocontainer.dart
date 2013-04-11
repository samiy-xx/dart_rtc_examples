part of demo_client;

class VideoContainer extends MediaContainer {
  String _aspectRatio;
  String get aspectRatio => _aspectRatio;
  Element get matcher => _media;
  VideoElement get video => _media;

  VideoContainer(MediaManager manager, String id) : super(manager, id){
    _media = new VideoElement();

    _media.onCanPlay.listen(_onCanPlay);
    _media.onPlay.listen(_onPlay);
    _media.onPause.listen(_onPause);
    _media.onEnded.listen(_onStop);
    _media.onLoadedMetadata.listen(_onMetadata);

    matcher.onClick.listen((e) {
      print(_id);
    });
  }

  void initialize([bool aux]) {
    _media.classes.add("vid");
    _media.id = "vid_${_id}";
    if (?aux)
      _media.classes.add("auxvid");
    _media.autoplay = true;
    (_media as VideoElement).poster = _manager._poster;
  }

  void destroy() {
    _media.pause();
    matcher.remove();
  }

  void _onMetadata(Event e) {
    VideoElement video = _media;
    _aspectRatio = Util.aspectRatio(video.videoWidth, video.videoHeight);
    _manager.setProportions(this);
  }

  void _onCanPlay(Event e) {

  }
  /**
   * Handle play event for video
   */
  void _onPlay(Event e) {

  }

  /**
   * Handle ended event for video
   */
  void _onStop(Event e) {

  }

  /**
   * Handle pause event for video
   */
  void _onPause(Event e) {

  }


}