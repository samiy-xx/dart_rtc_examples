part of demo_client;

abstract class PeerPacket {
  static const int TYPE_DIRECTORY_ENTRY = 1;
  static const int TYPE_REQUEST_FILE = 2;

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



