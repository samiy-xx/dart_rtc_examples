part of demo_client;

abstract class MediaManager {
  MediaContainer getMediaContainer(String id);
  MediaContainer addMediaContainer(String id);
  MediaStream _getLocalStream();
  void setContainer(Element e);

  String cssify(int m) {
    return m.toString() + "px";
  }
}
/**
 * Abstract VideoManager
 */
abstract class OldMediaManager {
  /** Sets the stream to VideoContainer */
  void setStream(MediaStream ms, VideoContainer c);
  void addStream(MediaStream ms, String id, [bool main]);
  void addRemoteStream(MediaStream ms, String id, [bool main]);
  /** Adds a new VideoContainer */
  VideoContainer addVideoContainer(String id);

  /** Removes a video container with id */
  void removeMediaContainer(VideoContainer vc);
  MediaStream getLocalStream();

}
