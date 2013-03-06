import "dart:html";
import "dart:async";
import '../lib/demo_client.dart';

//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

typedef void onClear();
typedef void onEntry(String name, int size);

void main() {
  int channelLimit = 2;
  String otherId;
  String currentRequestedFile = null;
  FileUploadInputElement fuie = query("#file");
  ButtonElement copyButton = query("#copy");
  ButtonElement removeButton = query("#remove");
  DivElement local_files = query("#local_files");
  DivElement remote_files = query("#remote_files");
  EntryManager em = new EntryManager(local_files, remote_files);
  FileManager fm = new FileManager(em);
  
  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);
  
  copyButton.onClick.listen((MouseEvent e) {
    List<String> files = em._selectedRemoteFiles;
    if (files.length > 0) {
      if (currentRequestedFile == null) {
        currentRequestedFile = files[0];
        qClient.sendPeerPacket(otherId, new RequestFilePacket(files[0]));
      } 
    }
  });
  
  removeButton.onClick.listen((MouseEvent e) {
    List<String> files = em._selectedLocalFiles;
    fm.removeFiles(files);
  });
  
  fuie.onChange.listen((Event e) {
    for (int i = 0; i < fuie.files.length; i++) {
      File file = fuie.files[i];
      
      fm.saveFile(file);
      qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(file.name, file.size));
    }
  });
  
  qClient.onInitializationStateChangeEvent.listen((InitializationStateEvent e) {
    if (e.state == InitializationState.CHANNEL_READY) {
      qClient.setChannelLimit(channelLimit);
    }

    if (e.state == InitializationState.REMOTE_READY) {
      qClient.joinChannel("abc");
    }
  });

  qClient.onSignalingOpenEvent.listen((SignalingOpenEvent e) {

  });

  qClient.onSignalingCloseEvent.listen((SignalingCloseEvent e) {
    new Timer(const Duration(milliseconds: 10000), () {
      qClient.initialize();
    });
  });

  qClient.onPacketEvent.listen((PacketEvent e) {
    print("packet ${e.type.toString()}");
    if (e.type.toString() == PacketType.ID.toString() || e.type.toString() == PacketType.JOIN.toString()) {
      print("assigning id ${e.packet.id}");
      //otherId = e.packet.id;
    }
  });

  qClient.onPeerStateChangeEvent.listen((PeerStateChangedEvent e) {
    if (e.state == PEER_STABLE) {
      otherId = e.peerwrapper.id;

      fm.getEntries().then((List<Entry> entries) {
        for (Entry entry in entries) {
          entry.getMetadata((Metadata m) {
            qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(entry.name, m.size));
          }, (FileError error) {});
        }
      });
    }
  });
  
  qClient.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
    }

    else if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
    }

    else if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
      fm.writeBuffer(bbc.buffer, currentRequestedFile);
      currentRequestedFile = null;
    }

    else if (e is BinaryPeerPacketEvent) {
      BinaryPeerPacketEvent bppe = e;
      switch (bppe.peerPacket.packetType) {
        case PeerPacket.TYPE_DIRECTORY_ENTRY:
          DirectoryEntryPacket dep = e.peerPacket;
          em.appendToRemoteFiles(dep.fileName, dep.fileSize);
          break;
        case PeerPacket.TYPE_REQUEST_FILE:
          RequestFilePacket rfp = e.peerPacket;
          fm.readFile(rfp.fileName).then((ArrayBuffer buffer) {
            qClient.sendArrayBuffer(otherId, buffer);
          });
          break;
        default:
          break;
      }
    }
  });

  qClient.initialize();
}

class EntryManager {
  Element _localFiles;
  Element _remoteFiles;
  List<String> _selectedLocalFiles;
  List<String> _selectedRemoteFiles;
  
  EntryManager(this._localFiles, this._remoteFiles) {
    _selectedLocalFiles = new List<String>();
    _selectedRemoteFiles = new List<String>();
  }
  
  void appendToLocalFiles(String name, int size, String url) {
    DivElement div = createEntry(name, size, url);
    _localFiles.append(div);
  }
  
  void appendToRemoteFiles(String name, int size) {
    DivElement div = createEntry(name, size);
    _remoteFiles.append(div);
  }
  
  void clearLocalFiles() {
    _localFiles.nodes.clear();
  }
  
  void clearRemoteFiles() {
    _remoteFiles.nodes.clear();
  }
  
  void removeFromLocalFiles(String name) {
    
  }
  
  void removeFromRemoteFiles(String name) {
    
  }
  
  void onSelectChange(Event e) {
    CheckboxInputElement cbx = e.target;
    DivElement parent = cbx.parent.parent;
    DivElement container = parent.parent;
    SpanElement span = parent.queryAll("span")[1];
    String fileName = span.text;
    
    List<String> files = container == _localFiles ? _selectedLocalFiles : _selectedRemoteFiles;
    
    if (cbx.checked) {
      if (!files.contains(fileName))
        files.add(fileName);
    } else {
      int index = files.indexOf(fileName);
      if (index >= 0)
        files.removeAt(index);
     
    }
    print(files.length);
  }
  
  DivElement createEntry(String name, int size, [String url]) {
    DivElement entryDiv = new DivElement();
    entryDiv.classes.add("file_entry_row");
    entryDiv.id = "div_$name";

    CheckboxInputElement cbx = new CheckboxInputElement();
    cbx.onChange.listen(onSelectChange);
    
    SpanElement selectSpan = new SpanElement();
    selectSpan.classes.add("file_entry_column");
    selectSpan.classes.add("file_entry_select");
    selectSpan.append(cbx);

    SpanElement fileNameSpan = new SpanElement();
    fileNameSpan.classes.add("file_entry_column");
    fileNameSpan.classes.add("file_entry_name");
    fileNameSpan.appendHtml(?url ? "<a href='$url'>$name</a>" : name);

    SpanElement fileSizeSpan = new SpanElement();
    fileSizeSpan.classes.add("file_entry_column");
    fileSizeSpan.classes.add("file_entry_size");
    fileSizeSpan.appendText(size.toString());

    entryDiv.append(selectSpan);
    entryDiv.append(fileNameSpan);
    entryDiv.append(fileSizeSpan);
    
    return entryDiv;
  }
}

class FileManager {
  FileSystem _fileSystem;
  DirectoryEntry _dir;
  String _rootDir = "mydocs";
  EntryManager _em;
  onEntry _entryCallback;
  onClear _clearCallback;

  set entryCallback(onEntry c) => _entryCallback = c;
  set clearCallback(onClear c) => _clearCallback = c;

  FileManager(EntryManager em) {
    _em = em;
    window.requestFileSystem(Window.TEMPORARY, 1024*1024*5, onFileSystem, onError);
  }

  void onFileSystem(FileSystem fs) {
    _fileSystem = fs;

    fs.root.getDirectory(_rootDir, options : {'create' : true}, successCallback : onDirectory, errorCallback: onError);
  }

  void onDirectory(DirectoryEntry dir) {
    _dir = dir;
    update();
  }
  
  void removeFiles(List<String> files) {
    for (String fileName in files) {
      removeFile(fileName);
    }
  }
  
  void removeFile(String fileName) {
    _dir.getFile(fileName, options : {'create': false}, successCallback : (FileEntry e) {
      e.remove(() {
        update();
      }, onError);
    }, errorCallback : onError);  
  }
  
  void writeBuffer(ArrayBuffer buffer, String name) {
    Blob b = new Blob([BinaryData.stringFromBuffer(buffer)]);
    saveBlob(b, name);
  }

  void saveBlob(Blob b, String name) {
    _dir.getFile(name, options: {'create':true, 'exclusive':true}, successCallback : (FileEntry fe) {
      fe.createWriter((FileWriter fw) {
        fw.write(b);
        update();
      }, onError);
    }, errorCallback: onError);
  }

  void saveFile(File f) {
    _dir.getFile(f.name, options: {'create':true, 'exclusive':true}, successCallback : (FileEntry fe) {
      fe.createWriter((FileWriter fw) {
        fw.write(f);
        update();
      }, onError);
    }, errorCallback: onError);
  }

  Future<ArrayBuffer> readFile(String name) {
    Completer completer = new Completer();
    _dir.getFile(name, options: {}, successCallback : (FileEntry fe) {
      fe.file((File f) {
        FileReader reader = new FileReader();
        reader.onLoadEnd.listen((ProgressEvent e) {
          completer.complete(reader.result);
        });
        reader.readAsArrayBuffer(f);
      }, onError);
    } , errorCallback: onError);

    return completer.future;
  }

  void update() {
    _em.clearLocalFiles();
    DirectoryReader dirReader = _dir.createReader();

    dirReader.readEntries((List<Entry> entries) {
      for (int i = 0; i < entries.length; i++) {
        Entry e = entries[i];
        e.getMetadata((Metadata m) {
          //_entryCallback(e.name, m.size);
          _em.appendToLocalFiles(e.name, m.size, e.toUrl());
        }, onError);

      }
    }, onError);
  }

  Future<List<Entry>> getEntries() {
    Completer completer = new Completer();
    DirectoryReader dirReader = _dir.createReader();
    dirReader.readEntries((List<Entry> entries) {
      completer.complete(entries);
    }, onError);
    return completer.future;
  }
  void onError(FileError e) {

  }
}
