part of demo_client;

class AudioContainer extends MediaContainer {
  AudioElement get audio => _media;

  /**
   * Constructor
   */
  AudioContainer(MediaManager manager, String id) : super(manager, id) {
    _media = new AudioElement();
    _media.onCanPlay.listen(_onCanPlay);
    _media.onLoadedMetadata.listen(_onMetadata);
  }

  void mute() {
    _media.muted = true;
  }

  void unmute() {
    _media.muted = false;
  }

  void initialize([bool aux]) {
    _media.autoplay = true;
    _media.controls = true;
  }

  void pause() {
    _media.pause();
  }

  void play() {
    _media.play();
  }

  void destroy() {
    _media.pause();
  }

  void _onMetadata(Event e) {

  }

  void _onCanPlay(Event e) {
    _media.play();
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