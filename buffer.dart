part of dcbot.plugin;

class BufferEntry {
  final String network;
  final String target;
  final String user;
  final String message;
  
  BufferEntry(this.network, this.target, this.user, this.message);
  
  Map toData() => {
    "network": network,
    "target": target,
    "from": user,
    "message": message
  };
}

class Buffer {

  static Map<String, Buffer> buffers = new Map<String, Buffer>();

  List<BufferEntry> messages = [];
  final int _limit = 30;
  int _tracker = 0;

  void _handle(BufferEntry entry) {
    if (entry.message.startsWith("s/")) return;

    if (_tracker > _limit - 1) _tracker = 0;
    messages[_tracker] = entry;
    _tracker++;
  }

  static void handle(Map<String, dynamic> data) {
    String network = data['network'];
    String target = data['target'];
    String message = data['message'];
    String user = data['from'];
    
    var buf = buffers["${network}${target}"];
    
    if (buf == null) {
      buf = new Buffer();
      buffers["${network}${target}"] = buf;
      for (int i = 0; i < 30; i++) buf.messages.add(null);
    }

    buf._handle(new BufferEntry(network, target, user, message));
  }

  static List<BufferEntry> get(String name) {
    var buf = buffers[name];
    if (buf == null) return <BufferEntry>[];

    var list = buf.messages;
    var tracker = buf._tracker;

    List<BufferEntry> newList = [];

    for (int i = buf._tracker - 1; i >= 0; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    for (int i = buf._limit - 1; i >= buf._tracker; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    return newList;
  }

  static void clear(String name) {
    var buf = buffers[name];
    if (buf != null) buf.messages.clear();
  }
}