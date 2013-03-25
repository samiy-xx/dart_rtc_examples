import "dart:html";
import "dart:async";
import "dart:crypto";

import '../lib/demo_client.dart';

//import 'package:dart_rtc_common/rtc_common.dart';
//import 'package:dart_rtc_client/rtc_client.dart';
import '../../dart_rtc_client/lib/rtc_client.dart';
import '../../dart_rtc_common/lib/rtc_common.dart';

typedef void onClear();
typedef void onEntry(String name, int size);
typedef void entryRequest(String name);

void main() {
  int channelLimit = 2;
  int receivedTotal = 0;
  String otherId;
  String currentRequestedFile = null;
  EntryManager em = new EntryManager();
  FileManager fm = new FileManager();
  
  ChannelClient qClient = new ChannelClient(new WebSocketDataSource("ws://127.0.0.1:8234/ws"))
  .setRequireAudio(false)
  .setRequireVideo(false)
  .setRequireDataChannel(true)
  .setAutoCreatePeer(true);
  
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

  qClient.onDataChannelStateChangeEvent.listen((DataChannelStateChangedEvent e) {
    print("Datachannel state change ${e.state}");
    if (e.state == "open") {
      // for canary, peer state change doesnt seem to fire on canary
      otherId = e.peerwrapper.id;
      fm.getEntries().then((List<Entry> entries) {
        for (Entry entry in entries) {
          entry.getMetadata().then((Metadata m) {
            qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(entry.name, m.size));
          });
        }
      });
    }
  });
  
  qClient.onPeerStateChangeEvent.listen((PeerStateChangedEvent e) {
    new Logger().Debug("Peer state changed to ${e.state}");
    if (e.state == PEER_STABLE) {
      new Logger().Debug("Peer state changed to stable");
      otherId = e.peerwrapper.id;
    }
  });
  
  qClient.onBinaryEvent.listen((RtcEvent e) {
    if (e is BinaryChunkEvent) {
      BinaryChunkEvent bce = e;
      receivedTotal += bce.bytes;
      em.setProgressCompletion(receivedTotal, bce.bytesTotal);
      em.setProgressMax(bce.totalSequences);
      em.setProgressValue(bce.sequence);
    }

    else if (e is BinarySendCompleteEvent) {
      BinarySendCompleteEvent bsce = e;
    }

    else if (e is BinaryBufferCompleteEvent) {
      BinaryBufferCompleteEvent bbc = e;
      fm.writeBuffer(bbc.buffer, currentRequestedFile);
      currentRequestedFile = null;
      receivedTotal = 0;
    }

    else if (e is BinaryPeerPacketEvent) {
      BinaryPeerPacketEvent bppe = e;
      switch (bppe.peerPacket.packetType) {
        case PeerPacket.TYPE_DIRECTORY_ENTRY:
          DirectoryEntryPacket dep = e.peerPacket as DirectoryEntryPacket;
          em.appendToRemoteFiles(dep.fileName, dep.fileSize);
          break;
        case PeerPacket.TYPE_REQUEST_FILE:
          RequestFilePacket rfp = e.peerPacket as RequestFilePacket;
          new Logger().Debug("Remote requested file ${rfp.fileName}");
          fm.readFile(rfp.fileName).then((ArrayBuffer buffer) {
            qClient.sendArrayBuffer(otherId, buffer).then((bool b) {
              new Logger().Debug("FILE SENT");
            });
          });
          break;
        default:
          break;
      }
    }
  });

  fm.onFileAddedEvent.listen((TmpFile f) {
    print("File packet send");
    qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(f.name, f.size));
  });
  
  fm.entryCallback = (String name, int size) {
    qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(name, size));
  };
  
  em.onEntryRequest = (String name) {
    currentRequestedFile = name;
    qClient.sendPeerPacket(otherId, new RequestFilePacket(name));
  };
  
  qClient.initialize();
}

class EntryManager {
  static EntryManager _instance;
  Element _localFiles;
  Element _remoteFiles;
  Element _buttonAddFiles;
  Element _buttonRemoveFiles;
  Element _buttonCopyFromRemote;
  Element _abortAll;
  Element _progressTotal;
  ProgressElement _progressElement;
  CheckboxInputElement _allLocal;
  CheckboxInputElement _allRemote;
  FileUploadInputElement _upload;
  List<String> _selectedLocalFiles;
  List<String> _selectedRemoteFiles;
  entryRequest _entryRequestCallback;
  set onEntryRequest(entryRequest c) => _entryRequestCallback = c;
  
  factory EntryManager() {
    if (_instance == null)
      _instance = new EntryManager._internal();
    
    return _instance;
  }
  
  EntryManager._internal() {
    
    _selectedLocalFiles = new List<String>();
    _selectedRemoteFiles = new List<String>();
    _localFiles = query("#left");
    _remoteFiles = query("#right");
    _allLocal = query("#all_local");
    _allRemote = query("#all_remote");
    _upload = new FileUploadInputElement();
    _upload.multiple = true;
    _buttonAddFiles = query("#button_add_files");
    _buttonRemoveFiles = query("#button_remove_files");
    _buttonCopyFromRemote = query("#copy_from_remote");
    _progressTotal = query("#progress_amount");
    _progressElement = query("#progress_bar");
    _abortAll = query("#abort_all");
  
    _setListeners();
  }
  
  void _setListeners() {
    _allLocal.onChange.listen((Event e) {
      List<Element> checkboxes = queryAll("#left .file_select");
      checkboxes.forEach((CheckboxInputElement input) {
        input.checked = (e.target as CheckboxInputElement).checked;
        input.blur();
      });
    });
    
    _allRemote.onChange.listen((Event e) {
      List<Element> checkboxes = queryAll("#right .file_select");
      checkboxes.forEach((CheckboxInputElement input) {
        input.checked = (e.target as CheckboxInputElement).checked;
      });
    });
    
    _buttonAddFiles.onClick.listen((Event e) {
      _upload.click();
    });
    
    _upload.onChange.listen((Event e) {
      for (int i = 0; i < _upload.files.length; i++) {
        File file = _upload.files[i];
        
        new FileManager().saveFile(file);
        //qClient.sendPeerPacket(otherId, new DirectoryEntryPacket(file.name, file.size));
      }
    });
    
    _buttonRemoveFiles.onClick.listen((Event e) {
      queryAll("#left .file_row").forEach((Element e) {
        CheckboxInputElement i = e.query(".file_select");
        if (i.checked) {
          Element j = e.query(".col_name");
          new FileManager().removeFile(j.text);
        }
      });
    });
    
    _buttonCopyFromRemote.onClick.listen((Event e) {
      queryAll("#right .file_row").forEach((Element e) {
        CheckboxInputElement i = e.query(".file_select");
        if (i.checked) {
          Element j = e.query(".col_name");
          print("#request file ${j.text}");
          _entryRequestCallback(j.text);
        }
      });
    });
    
    _abortAll.onClick.listen((Event e) {
      
    });
  }
  
  void setProgressMax(int value) {
    _progressElement.max = value;
  }
  
  void setProgressValue(int value) {
    _progressElement.value = value;
  }
  
  void setProgressCompletion(int value, int total) {
    _progressTotal.nodes.clear();
    _progressTotal.appendText("$value / $total");
  }
  
  void appendToLocalFiles(String name, int size, String url) {
    print("Append to local files");
    DivElement div = createEntry(name, size, url);
    _localFiles.append(div);
  }
  
  void appendToRemoteFiles(String name, int size) {
    if (haveThisEntry(name))
      return;
    
    DivElement div = createEntry(name, size);
    _remoteFiles.append(div);
  }
  
  void clearLocalFiles() {
    print("clear local files");
    _localFiles.queryAll(".file_row").forEach((Element e) {
      e.remove();
    });
  }
  
  void clearRemoteFiles() {
    _remoteFiles.queryAll(".file_row").forEach((Element e) {
      e.remove();
    });
  }
  
  bool haveThisEntry(String name) {
    return queryAll("#right .col_name").any((Element e) => e.text == name);
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
    entryDiv.classes.add("file_row");
    entryDiv.id = "div_$name";

    CheckboxInputElement cbx = new CheckboxInputElement();
    cbx.classes.add("file_select");
    cbx.onChange.listen(onSelectChange);
    
    SpanElement selectSpan = new SpanElement();
    selectSpan.classes.add("col_check");
    selectSpan.classes.add("file_col");
    selectSpan.append(cbx);

    SpanElement fileNameSpan = new SpanElement();
    fileNameSpan.classes.add("file_col");
    fileNameSpan.classes.add("col_name");
    fileNameSpan.appendHtml(?url ? "<a href='$url'>$name</a>" : name);

    SpanElement fileSizeSpan = new SpanElement();
    fileSizeSpan.classes.add("file_col");
    fileSizeSpan.classes.add("col_size");
    fileSizeSpan.appendText(size.toString());

    entryDiv.append(selectSpan);
    entryDiv.append(fileNameSpan);
    entryDiv.append(fileSizeSpan);
    
    return entryDiv;
  }
}

class FileManager {
  static FileManager _instance;
  FileSystem _fileSystem;
  DirectoryEntry _dir;
  String _rootDir = "mydocs";
  EntryManager _em;
  onEntry _entryCallback;
  onClear _clearCallback;

  StreamController<TmpFile> _fileAddedStreamController;
  Stream<TmpFile> get onFileAddedEvent  => _fileAddedStreamController.stream;
  set entryCallback(onEntry c) => _entryCallback = c;
  set clearCallback(onClear c) => _clearCallback = c;

  factory FileManager() {
    if (_instance == null)
      _instance = new FileManager._internal();
    
    return _instance;
  }
  
  FileManager._internal() {
    _em = new EntryManager();
    _fileAddedStreamController = new StreamController<TmpFile>.broadcast();
    //window.requestFileSystem(Window.TEMPORARY, 1024*1024*5, onFileSystem, onError);
    window.requestFileSystem(1024*1024*5)
    .then(onFileSystem)
    .catchError((AsyncError e) => onError(e.error));
  }

  
  void onFileSystem(FileSystem fs) {
    _fileSystem = fs;

    //fs.root.getDirectory(_rootDir, options : {'create' : true}, successCallback : onDirectory, errorCallback: onError);
    //fs.root.getDirectory(_rootDir, options : {'create' : true}).then(onDirectory);
    fs.root.getDirectory(_rootDir).then(onDirectory);
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
    //_dir.getFile(fileName, options : {'create': false}).then((FileEntry e) {
    
    _dir.getFile(fileName).then((FileEntry fe) {
      fe.remove().then((f) => update()).catchError((AsyncError e) => onError(e.error));
    })
    .catchError((AsyncError e) => onError(e.error));
  }
  
  void writeBuffer(ArrayBuffer buffer, String name) {
    Blob b = new Blob([new Uint8Array.fromBuffer(buffer)]);
    print("Saving blob ${b.size} bytes");
    saveBlob(b, name);
  }

  void saveBlob(Blob b, String name) {
    _dir.createFile(name)
    .then((FileEntry fe) {
      fe.createWriter().then((FileWriter fw) {
        fw.write(b);
        //_entryCallback(name, b.size);
        if (_fileAddedStreamController.hasSubscribers)
          _fileAddedStreamController.add(new TmpFile(b.size, name));
        print("Blob saved to disk");
        update();
      });
    })
    .catchError((AsyncError e) {
      new Logger().Error("Error creating file");
      onError(e.error);
    });
    
  }

  void saveFile(File f) {
    _dir.createFile(f.name)
    .then((FileEntry fe) {
      fe.createWriter().then((FileWriter fw) {
        fw.write(f);
        //_entryCallback(f.name, f.size);
        if (_fileAddedStreamController.hasSubscribers) {
          print ("notify listeners");
          _fileAddedStreamController.add(new TmpFile(f.size, f.name));
        }
        print("Blob saved to disk");
        update();
      });
    })
    .catchError((AsyncError e) {
      new Logger().Error("Error creating file");
      onError(e.error);
    });
    
  }

  Future<ArrayBuffer> readFile(String name) {
    Completer completer = new Completer();
    //_dir.getFile(name, options: {})
    _dir.getFile(name)
    .then((FileEntry fe) {
      fe.file().then((File f) {
        FileReader reader = new FileReader();
        reader.onLoadEnd.listen((ProgressEvent e) {
          completer.complete(reader.result);
        });
        reader.onProgress.listen((ProgressEvent e) {
        
        });
        reader.readAsArrayBuffer(f);
      });
    });
    /*_dir.getFile(name, options: {}, successCallback : (FileEntry fe) {
      fe.file((File f) {
        FileReader reader = new FileReader();
        reader.onLoadEnd.listen((ProgressEvent e) {
          completer.complete(reader.result);
        });
        reader.readAsArrayBuffer(f);
      }, onError);
    } , errorCallback: onError);*/

    return completer.future;
  }

  void update() {
    _em.clearLocalFiles();
    DirectoryReader dirReader = _dir.createReader();
    dirReader.readEntries().then((List<Entry> entries) {
      for (int i = 0; i < entries.length; i++) {
        Entry e = entries[i];
        e.getMetadata().then((Metadata m) {
          _em.appendToLocalFiles(e.name, m.size, e.toUrl());
        });
      }
    });
    /*dirReader.readEntries((List<Entry> entries) {
      for (int i = 0; i < entries.length; i++) {
        Entry e = entries[i];
        e.getMetadata((Metadata m) {
          //_entryCallback(e.name, m.size);
          _em.appendToLocalFiles(e.name, m.size, e.toUrl());
        }, onError);

      }
    }, onError);*/
  }

  Future<List<Entry>> getEntries() {
    Completer completer = new Completer();
    DirectoryReader dirReader = _dir.createReader();
    dirReader.readEntries().then((List<Entry> entries) {
      completer.complete(entries);
    });
    /*dirReader.readEntries((List<Entry> entries) {
      completer.complete(entries);
    }, onError);*/
    return completer.future;
  }
  
  void onError(FileError e) {
    String error;
    switch (e.code) {
      case FileError.ABORT_ERR:
        error = "Abort error";
        break;
      case FileError.ENCODING_ERR:
        error = "Encoding error";
        break;
      case FileError.INVALID_MODIFICATION_ERR:
        error = "Invalid modification error";
        break;
      case FileError.INVALID_STATE_ERR:
        error = "Invalid state error";
        break;
      case FileError.NO_MODIFICATION_ALLOWED_ERR:
        error = "No modification allowed error";
        break;
      case FileError.NOT_FOUND_ERR:
        error = "Not found error";
        break;
      case FileError.NOT_READABLE_ERR:
        error = "Not readable error";
        break;
      case FileError.PATH_EXISTS_ERR:
        error = "Path exists error";
        break;
      case FileError.QUOTA_EXCEEDED_ERR:
        error = "Quota exceeded error";
        break;
      case FileError.SECURITY_ERR:
        error = "Security error";
        break;
      case FileError.SYNTAX_ERR:
        error = "Syntax error";
        break;
      case FileError.TYPE_MISMATCH_ERR:
        error = "Type mismatch error";
        break;
      default:
        error = "Unknown error ${e.code}";
    }
    
    print("FILE Error $error");
  }
}

class TmpFile {
  int size;
  String name;
  
  TmpFile(this.size, this.name);
}