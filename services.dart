part of dcbot.plugin;

class ServiceEventBus {
  final String url;
  final String token;

  List<String> _queue = [];

  WebSocket _socket;

  StreamController<Map<String, dynamic>> _controller = new StreamController();
  Stream<Map<String, dynamic>> _stream;

  ServiceEventBus(this.url, this.token) {
    _stream = _controller.stream.asBroadcastStream();
    _init();
  }

  void _init() {
    onMessage("connect").listen((event) {
      sendMessage("connect", {
        "token": token
      });

      while (_queue.isNotEmpty) {
        _socket.add(_queue.removeAt(0));
      }
    });
  }

  Future connect() {
    return WebSocket.connect(url).then((socket) {
      _socket = socket;

      socket.listen((data) {
        var json = JSON.decode(data);
        _controller.add(json);
        print(json);
      });
    });
  }

  void _sendJSON(object) {
    if (_socket == null) {
      _queue.add(JSON.encode(object));
    } else {
      _socket.add(JSON.encode(object));
    }
  }

  Stream<Map<String, dynamic>> onMessage(String type) {
    return _stream.where((event) => event['type'] == type);
  }

  Stream<Map<String, dynamic>> on(String event) {
    return onMessage("event").where((it) => it['event'] == event).map((it) {
      return it['data'];
    });
  }

  void sendMessage(String type, Map params) {
    _sendJSON({
      "type": type
    }..addAll(params));
  }

  void subscribe(e) {
    var events = e is String ? [e] : e;
    for (var event in events) {
      sendMessage("register", {
        "event": event
      });
    }
  }

  void unsubscribe(e) {
    var events = e is String ? [e] : e;
    for (var event in events) {
      sendMessage("unregister", {
        "event": event
      });
    }
  }

  void emit(String event, Map data) {
    sendMessage("emit", {
      "event": event,
      "data": data
    });
  }
}

ServiceEventBus eventBus;

void setupServices() {
  eventBus = new ServiceEventBus("ws://${servicesUrl}/events/ws", servicesToken);
  eventBus.connect().then((_) {
    print("Connected to Event Bus");
  });

  eventBus.subscribe([
    "members.added",
    "members.removed"
  ]);

  eventBus.on("members.added").listen((event) {
    bot.message("EsperNet", "#directcode", "${fancyPrefix("DirectCode")} ${event['name']} is now a member");
  });

  eventBus.on("members.removed").listen((event) {
    bot.message("EsperNet", "#directcode", "${fancyPrefix("DirectCode")} ${event['name']} is no longer a member");
  });
}

const String servicesUrl = "services.directcode.org";

String servicesToken;

void handleServicesCommand(CustomCommandEvent event) {
  switch (event.command) {
    case "list-members":
      http.get("http://" + servicesUrl + "/api/members/list").then((response) {
        var json = JSON.decode(response.body);

        var out = json.map((it) => it['name']).join(", ");

        event.reply("Members: ${out}", prefixContent: "DirectCode");
      });
      break;
  }
}