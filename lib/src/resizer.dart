part of demo_client;

class Resizer {
  Element _e;

  int _requestedWidth;
  int _requestedHeight;
  int _requestedX;
  int _requestedY;

  int _width;
  int _height;
  int _x;
  int _y;
  Timer _timer = null;
  static const int _loopInterval = 5;

  Resizer(Element e, int w, int h, int x, int y) {
    _e = e;
    _e.style.position = "absolute";

    setPosition(x, y);
    setSize(w, h);
    _requestedX = x;
    _requestedY = y;
    _requestedWidth = w;
    _requestedHeight = h;

  }

  void requestNewSize(int w, int h) {
    _requestedWidth = w;
    _requestedHeight = h;

    if (_timer == null)
      startLoop();
  }

  void requestNewPosition(int x, int y) {
    _requestedX = x;
    _requestedY = y;

    if (_timer == null)
      startLoop();
  }
  bool setSize(int w, int h) {
    if (w == _width && h == _height)
      return true;

    _width = w;
    _height = h;

    resize(w, h);
    return false;
  }

  bool setPosition(int x, int y) {
    if (x == _x && y == _y)
      return true;

    _x = x;
    _y = y;

    moveElement(x, y);
    return false;
  }

  void moveElement(int x, int y) {
    _e.style.left = cssUnit(x);
    _e.style.top = cssUnit(y);
  }

  void resize(int w, int h) {
    _e.style.width = cssUnit(w);
    _e.style.height = cssUnit(h);
  }

  void startLoop() {
    _timer = new Timer.periodic(const Duration(milliseconds: _loopInterval), (Timer t) {

      int newWidth = _width;
      int newHeight = _height;
      int newX = _x;
      int newY = _y;

      if (_width != _requestedWidth) {
        newWidth += (_requestedWidth > _width) ? 1 : -1;
      }

      if (_height != _requestedHeight) {
        newHeight += (_requestedHeight > _height) ? 1 : -1;
      }

      if (_x != _requestedX) {
        newX += (_requestedX > _x) ? 1 : -1;
      }

      if (_y != _requestedY) {
        newY += (_requestedY > _y) ? 1 : -1;
      }

      if (setSize(newWidth, newHeight) && setPosition(newX, newY)) {
        cancelLoop();
      }
    });
  }

  void cancelLoop() {

    _timer.cancel();
    _timer = null;

  }

  String cssUnit(int w) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(w.toString());
    buffer.write("px");
    return buffer.toString();
  }
}