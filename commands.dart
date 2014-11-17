part of dcbot.plugin;

const String BASE_DARTDOC = "http://www.dartdocs.org/documentation/";

class CustomCommandEvent {
  final String network;
  final String command;
  final String message;
  final String user;
  final String channel;
  final List<String> args;

  void reply(String message, {bool prefix: true, String prefixContent: "DCBot"}) {
    bot.message(network, channel, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  void require(String permission, void handle()) {
    bot.permission((it) => handle(), network, channel, user, permission);
  }

  void replyNotice(String message, {bool prefix: true, String prefixContent: "DCBot"}) {
    bot.notice(network, user, (prefix ? "[${Color.BLUE}${prefixContent}${Color.RESET}] " : "") + message);
  }

  CustomCommandEvent(this.network, this.command, this.message, this.user, this.channel, this.args);
}

void handleCommand(CustomCommandEvent event) {
  if (event.channel.toLowerCase() == "#directcode") {
    switch (event.command) {
      case "github":
        event.reply("GitHub Organization: https://github.com/DirectMyFile", prefixContent: "DirectCode");
        break;
      case "board":
        event.reply("All Ops are Board Members", prefixContent: "DirectCode");
        break;
      case "members":
        event.reply("All Voices are Members", prefixContent: "DirectCode");
        break;
      case "join-directcode":
        event.reply("To become a member, contact a board member.", prefixContent: "DirectCode");
        break;
    }
  }

  var countdowns = [];

  switch (event.command) {
    case "broken":
      if (event.args.length == 0) {
        event.reply("kaendfinger breaks all the things.", prefix: false);
      } else {
        event.reply("${event.args.join(' ')} breaks all the things.", prefix: false);
      }
      break;
    case "uptime":
      var diff = new DateTime.now().difference(startTime);
      var str = "${diff.inDays} days, ${diff.inHours} hours, ${diff.inMinutes} minutes, ${diff.inSeconds} seconds";
      event.reply("${str}", prefixContent: "Uptime");
      break;
    case "countdown":
      if (event.args.length != 1) {
        event.reply("Usage: countdown <seconds>", prefixContent: "Countdown");
        return;
      }

      int seconds;

      try {
        seconds = int.parse(event.args[0]);
      } catch (e) {
        event.reply("Invalid Number", prefixContent: "Countdown");
        return;
      }

      int i = seconds;
      Timer timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
        if (i > 5 && !((i % 5) == 0)) {
          return;
        }

        event.reply("${i}", prefixContent: "Countdown");

        if (i == 0) {
          event.reply("Complete.", prefixContent: "Countdown");
          timer.cancel();
          countdowns.remove(timer);
        }

        i--;
      });

      countdowns.add(timer);
      break;
    case "hammertime":
      if (event.args.length == 0) {
        event.reply("U can't touch this.", prefix: false);
      } else {
        event.reply("U can't touch ${event.args.join(' ')}.", prefix: false);
      }
      break;
    case "hammer":
      event.reply(repeat("\u25AC", 4) + "\u258B", prefix: false);
      break;
    case "banhammer":
      event.reply("Somebody is bringing out the ban hammer! ${repeat("\u25AC", 4)}\u258B Ò╭╮Ó", prefix: false);
      break;
    case "today":
    case "date":
      event.reply(friendlyDate(new DateTime.now()), prefixContent: "Date");
      break;
    case "time":
      event.reply(friendlyTime(new DateTime.now()), prefixContent: "Time");
      break;
    case "now":
      event.reply("Now is " + friendlyDateTime(new DateTime.now()));
      break;
    case "yesterday":
      event.reply("Yesterday was " + friendlyDate(new DateTime.now().subtract(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "tomorrow":
      event.reply("Tomorrow will be " + friendlyDate(new DateTime.now().add(new Duration(days: 1))), prefixContent: "DCBot");
      break;
    case "dfn":
      if (event.args.length != 1) {
        event.reply("> Usage: dfn <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(event.args[0]);

        if (days >= 100000000) {
          throw "FAIL";
        }
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.", prefix: false);
        return;
      }
      event.reply("${days} day${days != 1 ? "s" : ""} from now will be ${friendlyDate(new DateTime.now().add(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "dag":
      if (event.args.length != 1) {
        event.reply("> Usage: dag <days>", prefix: false);
        return;
      }
      int days;
      try {
        days = int.parse(event.args[0]);

        if (days >= 100000000) {
          throw "FAIL";
        }
      } catch (e) {
        event.reply("> ${event.args[0]} is not a valid number.", prefix: false);
        return;
      }
      event.reply("${days} day${days != 1 ? "s" : ""} ago was ${friendlyDate(new DateTime.now().subtract(new Duration(days: days)))}", prefixContent: "DCBot");
      break;
    case "help":
      event.replyNotice("DCBot is the official DirectCode IRC Bot.", prefixContent: "Help");
      event.replyNotice("For a list of commands, use \$commands", prefixContent: "Help");
      break;
    case "commands":
      bot.get("plugins").then((responseA) {
        List<String> pluginNames = responseA['plugins'];
        for (var plugin in pluginNames) {
          bot.get("plugin-commands", {
            "plugin": plugin
          }).then((Map<String, Map<String, dynamic>> cmds) {
            if (cmds == null) {
              return;
            }
            event.replyNotice("${plugin}: ${cmds.isEmpty ? "No Commands" : cmds.keys.join(', ')}", prefixContent: "Commands");
          });
        }
      });
      break;
    case "command":
      if (event.args.length != 1) {
        event.reply("Usage: command <command name>", prefixContent: "Command Information");
      }

      bot.get("command-exists", {
        "command": event.args[0]
      }).then((response) {
        var exists = response['exists'];
        if (exists) {
          return bot.get("command-info", {
            "command": event.args[0]
          });
        } else {
          event.reply("Unknown Command: ${event.args[0]}", prefixContent: "Command Information");
        }
      }).then((info) {
        var usage = info["usage"];
        var description = info["description"];

        if (description != null) {
          event.reply("Description: ${description}", prefixContent: "Command Information");
        }

        if (usage != null) {
          event.reply("Usage: ${event.args[0]} ${usage}", prefixContent: "Command Information");
        }
      });
      break;
    case "plugins":
      bot.get("plugins").then((response) {
        event.reply("${response['plugins'].join(', ')}", prefixContent: "Plugins");
      });
      break;
    case "stats":
      var msgsTotal = storage.get("messages_total", 0);
      var cmdsTotal = storage.get("commands_total", 0);
      var networkMsgsTotal = storage.get("${event.network}_messages_total", 0);
      var networkCmdsTotal = storage.get("${event.network}_commands_total", 0);
      var channelMsgsTotal = storage.get("${event.network}_${event.channel}_messages_total", 0);
      var channelCmdsTotal = storage.get("${event.network}_${event.channel}_commands_total", 0);

      event.replyNotice("Bot - Total Messages: ${msgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Users - Total Command Runs: ${cmdsTotal}", prefixContent: "Statistics");
      event.replyNotice("Network - Total Messages: ${networkMsgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Channel - Total Messages: ${channelMsgsTotal}", prefixContent: "Statistics");
      event.replyNotice("Network - Total Command Runs: ${cmdsTotal}", prefixContent: "Statistics");
      event.replyNotice("Channel - Total Command Runs: ${channelCmdsTotal}", prefixContent: "Statistics");

      {
        var users = [];
        storage.map.keys.where((it) => it.startsWith("${event.network}_${event.channel}_user_")).forEach((name) {
          users.add({
            "name": name.replaceAll("${event.network}_${event.channel}_user_", "").replaceAll("_messages_total", ""),
            "count": storage.get(name)
          });
        });

        users.sort((a, b) => b['count'].compareTo(a['count']));

        if (users.isNotEmpty) {
          var most = users.first['name'];

          event.replyNotice("Most Talkative User on ${event.channel}: ${most}", prefixContent: "Statistics");
        }
      }
      break;
    case "month":
      var m = new DateTime.now().month;
      event.reply("The Month is ${monthName(m)} (the ${m}${friendlyDaySuffix(m)} month)", prefixContent: "DCBot");
      break;
    case "day":
      event.reply("The Day is ${dayName(new DateTime.now().weekday)}", prefixContent: "DCBot");
      break;
    case "dart-version":
      if (event.args.length >= 2) {
        event.reply("Usage: dart-version [channel]");
        return;
      }
      var chan = event.args.length == 1 ? event.args[0] : "stable";
      new HttpClient().getUrl(Uri.parse("https://commondatastorage.googleapis.com/dart-archive/channels/${chan}/${chan == "stable" ? "release" : "raw"}/latest/VERSION")).then((req) => req.close()).then((response) {
        response.transform(UTF8.decoder).join().then((value) {
          if (response.statusCode != 200) {
            event.reply("Invalid Channel", prefixContent: "Dart");
            return;
          }
          var json = JSON.decode(value);
          var rev = json['revision'];
          var v = json['version'];
          event.reply("${v} (${rev})", prefixContent: "Dart");
        });
      });
      break;
    case "reload":
      event.require("plugins.reload", () {
        event.reply("Reloading Plugins", prefixContent: "Plugin Manager");
        bot.send("reload-plugins", {
          "network": event.network
        });
      });
      break;
    case "year":
      event.reply("The Year is ${new DateTime.now().year}", prefixContent: "DCBot");
      break;
    case "cycle":
      event.require("command.cycle", () {
        bot.send("part", {
          "network": event.network,
          "channel": event.channel
        });

        bot.send("join", {
          "network": event.network,
          "channel": event.channel
        });
      });
      break;
    case "dartdoc":
      if (event.args.length > 2 || event.args.length < 1) {
        event.reply("> Usage: dartdoc <package> [version]", prefix: false);
      } else {
        String package = event.args[0];
        String version = event.args.length == 2 ? event.args[1] : "latest";
        dartdocUrl(event.args[0], version).then((url) {
          if (url == null) {
            event.reply("> package not found '${package}@${version}'", prefix: false);
          } else {
            event.reply("> Documentation: ${url}", prefix: false);
          }
        });
      }
      break;
    case "pub-latest":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-latest <package>", prefix: false);
      } else {
        latestPubVersion(event.args[0]).then((version) {
          if (version == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Latest Version: ${version}", prefix: false);
          }
        });
      }
      break;
    case "pub-description":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-description <package>", prefix: false);
      } else {
        pubDescription(event.args[0]).then((desc) {
          if (desc == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Description: ${desc}", prefix: false);
          }
        });
      }
      break;
    case "pub-downloads":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-downloads <package>", prefix: false);
      } else {
        String package = event.args[0];
        pubPackage(package).then((info) {
          if (info == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Download Count: ${info["downloads"]}", prefix: false);
          }
        });
      }
      break;
    case "pub-uploaders":
      if (event.args.length == 0) {
        event.reply("> Usage: pub-uploaders <package>", prefix: false);
      } else {
        String package = event.args[0];
        pubUploaders(package).then((authors) {
          if (authors == null) {
            event.reply("> No Such Package: ${event.args[0]}", prefix: false);
          } else {
            event.reply("> Uploaders: ${authors.join(", ")}", prefix: false);
          }
        });
      }
      break;
    case "addtxtcmd":
      event.require("txtcmds.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addtxtcmd <command> <text>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.set(cmd, text);
          event.reply("Command Added", prefixContent: "Text Commands");
        }
      });
      break;
    case "removetxtcmd":
      event.require("txtcmds.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removetxtcmd <command>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.json.remove(cmd);
          event.reply("Command Removed", prefixContent: "Text Commands");
        }
      });
      break;
    case "addchannelcmd":
      event.require("txtcmds.channel.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addchannelcmd <command> <text>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.set(event.network + " " + event.channel + " " + cmd, text);
          event.reply("Command Added", prefixContent: "Text Commands");
        }
      });
      break;
    case "removechannelcmd":
      event.require("txtcmds.channel.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removechannelcmd <command>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.json.remove(event.network + " " + event.channel + " " + cmd);
          event.reply("Command Removed", prefixContent: "Text Commands");
        }
      });
      break;
    case "addgchannelcmd":
      event.require("txtcmds.channel.global.add", () {
        if (event.args.length < 2) {
          event.reply("Usage: addgchannelcmd <command> <text>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          var text = event.args.sublist(1).join(" ");
          textCommandStorage.set(event.channel + " " + cmd, text);
          event.reply("Command Added", prefixContent: "Text Commands");
        }
      });
      break;
    case "removegchannelcmd":
      event.require("txtcmds.channel.global.remove", () {
        if (event.args.length != 1) {
          event.reply("Usage: removegchannelcmd <command>", prefixContent: "Text Commands");
        } else {
          var cmd = event.args[0];
          textCommandStorage.json.remove(event.channel + " " + cmd);
          event.reply("Command Removed", prefixContent: "Text Commands");
        }
      });
      break;
    case "about-bot":
      event.replyNotice("I am written in 100% Dart. I use isolates to separate functionality into plugins. This allows me to reload plugins without restarting the full bot.");
      event.replyNotice("You can find most of my functionality here: https://github.com/PolymorphicBot/");
      break;
    case "whatis":
      APIDocs.handleWhatIsCmd(event);
      break;
    case "neo":
      Neo.handleCommand(event);
      break;
    case "toggle-markov":
      event.require("markov.toggle", () {
        markovEnabled = !markovEnabled;
        if (markovEnabled) {
          event.reply("Enabled", prefixContent: "Markov Chain");
        } else {
          event.reply("Disabled", prefixContent: "Markov Chain");
        }
      });
      break;
    case "markov-random":
      event.reply(markov.randomSentence(), prefix: false);
      break;
    case "markov-stats":
      event.reply(markov.generateStatistics(), prefix: false);
      break;
    case "markov-wordstats":
      event.reply(markov.generateWordStats(event.args), prefix: false);
      break;
    case "linux-stable":
      new HttpClient().getUrl(Uri.parse('https://www.kernel.org/releases.json')).then((req) => req.close()).then((response) {
        response.transform(UTF8.decoder).join().then((value) {
          var json = JSON.decode(value);
          var latestStable = json['latest_stable'];
          event.reply("Latest Stable: ${latestStable["version"]}", prefixContent: "Linux");
        });
      });
      break;
  }
}

Future<String> dartdocUrl(String package, [String version = "latest"]) {
  if (version == "latest") {
    return latestPubVersion(package).then((version) {
      if (version == null) {
        return new Future.value(null);
      }
      return new Future.value("${BASE_DARTDOC}${package}/${version}");
    });
  } else {
    return new Future.value("${BASE_DARTDOC}${package}/${version}");
  }
}

Future<Map<String, Object>> pubPackage(String package) {
  return httpClient.get("https://pub.dartlang.org/api/packages/${package}").then((http.Response response) {
    if (response.statusCode == 404) {
      return new Future.value(null);
    } else {
      return new Future.value(JSON.decoder.convert(response.body));
    }
  });
}

Future<String> pubDescription(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["description"]);
    }
  });
}

Future<List<String>> pubUploaders(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["uploaders"]);
    }
  });
}

Future<List<String>> pubVersions(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      var versions = [];
      val["versions"].forEach((version) {
        versions.add(version["name"]);
      });
      return new Future.value(versions);
    }
  });
}

Future<String> latestPubVersion(String package) {
  return pubPackage(package).then((val) {
    if (val == null) {
      return new Future.value(null);
    } else {
      return new Future.value(val["latest"]["pubspec"]["version"]);
    }
  });
}
