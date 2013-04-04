part of demo_client;

abstract class PeerPacket {
  static const int TYPE_DIRECTORY_ENTRY = 1;
  static const int TYPE_REQUEST_FILE = 2;
  static const int TYPE_START_DRAW = 3;
  static const int TYPE_UPDATE_DRAW = 4;
  static const int TYPE_END_DRAW = 5;
  final int _packetType;
  int get packetType;

  PeerPacket(int type) : _packetType = type;

  Map toMap();
  ArrayBuffer toBuffer() {
    String toBuffer = json.stringify(toMap());
    return BinaryData.bufferFromString(toBuffer);
  }
}

class DirectoryEntryPacket extends PeerPacket {
  String fileName;
  int fileSize;

  int get packetType => _packetType;
  DirectoryEntryPacket(this.fileName, this.fileSize) : super(PeerPacket.TYPE_DIRECTORY_ENTRY);

  Map toMap() {
    return {
      'packetType' : _packetType,
      'fileName': fileName,
      'fileSize': fileSize
    };
  }

  static DirectoryEntryPacket fromMap(Map m) {
    return new DirectoryEntryPacket(m['fileName'], m['fileSize']);
  }

  static DirectoryEntryPacket fromBuffer(ArrayBuffer buffer) {
    String s = BinaryData.stringFromBuffer(buffer);
    Map m = json.parse(s);
    return fromMap(m);
  }
}

class RequestFilePacket extends PeerPacket {
  String fileName;
  int get packetType => _packetType;

  RequestFilePacket(this.fileName) : super(PeerPacket.TYPE_REQUEST_FILE);

  Map toMap() {
    return {
      'packetType' : _packetType,
      'fileName': fileName
    };
  }

  static RequestFilePacket fromMap(Map m) {
    return new RequestFilePacket(m['fileName']);
  }

  static RequestFilePacket fromBuffer(ArrayBuffer buffer) {
    String s = BinaryData.stringFromBuffer(buffer);
    Map m = json.parse(s);
    return fromMap(m);
  }
}

class StartDrawPacket extends PeerPacket {
  int get packetType => _packetType;
  int x;
  int y;
  StartDrawPacket(this.x, this.y) : super(PeerPacket.TYPE_START_DRAW);

  Map toMap() {
    return {
      'packetType' : _packetType,
      'x': x,
      'y': y
    };
  }

  static StartDrawPacket fromMap(Map m) {
    return new StartDrawPacket(m['x'], m['y']);
  }

  static StartDrawPacket fromBuffer(ArrayBuffer buffer) {
    String s = BinaryData.stringFromBuffer(buffer);
    Map m = json.parse(s);
    return fromMap(m);
  }
}

class UpdateDrawPacket extends PeerPacket {
  int get packetType => _packetType;
  int x;
  int y;
  UpdateDrawPacket(this.x, this.y) : super(PeerPacket.TYPE_UPDATE_DRAW);

  Map toMap() {
    return {
      'packetType' : _packetType,
      'x': x,
      'y': y
    };
  }

  static UpdateDrawPacket fromMap(Map m) {
    return new UpdateDrawPacket(m['x'], m['y']);
  }

  static UpdateDrawPacket fromBuffer(ArrayBuffer buffer) {
    String s = BinaryData.stringFromBuffer(buffer);
    Map m = json.parse(s);
    return fromMap(m);
  }
}

class EndDrawPacket extends PeerPacket {
  int get packetType => _packetType;
  int x;
  int y;
  EndDrawPacket(this.x, this.y) : super(PeerPacket.TYPE_END_DRAW);

  Map toMap() {
    return {
      'packetType' : _packetType,
      'x': x,
      'y': y
    };
  }

  static EndDrawPacket fromMap(Map m) {
    return new EndDrawPacket(m['x'], m['y']);
  }

  static EndDrawPacket fromBuffer(ArrayBuffer buffer) {
    String s = BinaryData.stringFromBuffer(buffer);
    Map m = json.parse(s);
    return fromMap(m);
  }
}


