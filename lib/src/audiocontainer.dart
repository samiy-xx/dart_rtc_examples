part of demo_client;

class AudioContainer extends MediaContainer {
  MediaManager _manager;
  AudioElement _audio;
  DivElement _div;

  String _id;
  String _url;

  Element get matcher => _audio;
  AudioElement get audio => _audio;
  set id(String value) => _id = value;
  String get id => _id;
  const String CSS_HIDDEN = "hidden";
  const String CSS_VISIBLE = "visible";

  /**
   * Constructor
   */
  AudioContainer(MediaManager manager, String id) {
    _manager = manager;
    _id = id;
    _audio = new AudioElement();
    _div = new DivElement();

    _div.nodes.add(_audio);

    _audio.onCanPlay.listen(_onCanPlay);
    _audio.onPlay.listen(_onPlay);
    _audio.onPause.listen(_onPause);
    _audio.onEnded.listen(_onStop);
    _audio.onLoadedMetadata.listen(_onMetadata);
  }


  void initialize([bool aux]) {
    _audio.autoplay = true;
    _audio.controls = true;
  }

  void pause() {
    _audio.pause();
  }

  void play() {
    _audio.play();
  }

  void setStream(MediaStream m) {
    _url = Url.createObjectUrl(m);
    setUrl(_url);
  }

  void setUrl(String url) {
    _audio.src = url;
  }

  void destroy() {
    _audio.pause();
    matcher.remove();
  }

  void _onMetadata(Event e) {

  }

  void _onCanPlay(Event e) {
    _audio.play();
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