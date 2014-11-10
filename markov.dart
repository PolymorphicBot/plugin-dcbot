library dcbot.markov;

import "dart:io";
import "dart:math" as Math;
import "dart:collection";

class MarkovChain {
  Math.Random random = new Math.Random();

  Map<String, List<int>> wordPairsNext = new Map<String, List<int>>();
  Map<String, List<int>> wordPairsPrevious = new Map<String, List<int>>();

  Map<String, List<int>> wordsNext = new Map<String, List<int>>();
  Map<String, List<int>> wordsPrevious = new Map<String, List<int>>();
  Set<String> lines = new Set<String>();

  IntMap<String, Word> words = new IntMap<String, Word>();

  void addLine(String line) {
    print("Adding '${line}'");
    {
      var lines = splitMultiple(line, [". ", "\n"]);
      for (var currentLine in lines) {
        if (!lines.contains(currentLine)) {
          lines.add(currentLine);
        } else {
          continue;
        }
        var currentWords = currentLine.split(" ");
        currentWords.add("");
        var previousWord = "";
        List<int> pairList = null;
        List<int> wordList = null;
        String currentWord;
        String nextWord;
        String pair;
        for (int i = 0; i < currentWords.length - 1; i++) {
          currentWord = _selectivelyLowercase(currentWords[i]);
          nextWord = _selectivelyLowercase(currentWords[i + 1]);
          pair = previousWord + " " + currentWord;
          int wordIndex = words.lookup(nextWord);
          if (wordIndex == null) {
            wordIndex = words.add(new Word(nextWord), nextWord);
          } else {
            words.get(wordIndex).increment();
          }
          pairList = wordPairsNext[pair];
          if (pairList == null) {
            pairList = [];
          }
          pairList.add(wordIndex);
          wordPairsNext[pair] = pairList;
          wordList = wordsNext[currentWord];
          if (wordList == null) wordList = [];
          wordList.add(wordIndex);
          wordsNext[currentWord] = wordList;
          wordIndex = words.lookup(previousWord);
          if (wordIndex == null) wordIndex = words.add(new Word(previousWord), previousWord);
          pair = currentWord + " " + nextWord;
          pairList = wordPairsNext[pair];
          if (pairList == null) pairList = [];
          pairList.add(wordIndex);
          wordPairsPrevious[pair] = pairList;
          wordList = wordsPrevious[currentWord];
          if (wordList == null) wordList = [];
          wordList.add(wordIndex);
          wordsPrevious[currentWord] = wordList;
          previousWord = currentWord;
        }
      }
    }
  }

  String reply(String inputString, [String name = "", String sender = ""]) {
    List<String> currentLines;
    List<String> currentWords = [];
    Queue<String> sentence = new Queue();

    String allSentences = "";
    String replyString = "";

    if (inputString.isEmpty) {
      return "";
    }

    currentLines = inputString.split(". ");
    currentWords.addAll(currentLines[currentLines.length - 1].split(" "));
    
    if (currentLines.length > 0) {
      for (int i = 0; i < currentLines.length - 1; i++) {
        allSentences += reply(currentLines[i]) + ". ";
      }
    }

    for (int i = 0; i < currentWords.length; i++) {
      currentWords[i] = _selectivelyLowercase(currentWords[i]);
    }

    if (currentWords.isEmpty) {
      return "";
    }

    String previousWord = "";
    String bestWord = currentWords[0];
    String bestWordPair = " " + currentWords[0];

    if (currentWords.length > 1) {
      bestWord = currentWords[random.nextInt(currentWords.length - 1)];
      int pairStart = random.nextInt(currentWords.length - 1);
      bestWordPair = (pairStart == 0 ? "" : currentWords[pairStart - 1]) + " " + currentWords[pairStart];
    }

    for (int i = 0; i < currentWords.length; i++) {
      var currentWord = currentWords[i];
      var pairKey = previousWord + " " + currentWord;
      int wordSize = (wordPairsNext[pairKey] != null ? wordPairsNext[pairKey].length : 0)
          + (wordPairsPrevious[pairKey] != null ? wordPairsPrevious.length : 0);
      int bestSize = (wordPairsNext[bestWordPair] != null ? wordPairsNext[bestWordPair].length : 0) +
          (wordPairsPrevious[bestWordPair] != null ? wordPairsPrevious.length : 0);

      if (bestSize == 0) bestWordPair = pairKey;

      wordSize = (wordsNext[currentWord] != null ? wordsNext[currentWord].length : 0)
          + (wordsPrevious[currentWord] != null ? wordsPrevious.length : 0);
      bestSize = (wordsNext[bestWord] != null ? wordsNext[bestWord].length : 0)
          + (wordsPrevious[bestWord] != null ? wordsPrevious.length : 0);
      
      if (bestSize == 0) bestWord = currentWord;

      previousWord = currentWord;
    }

    List<int> bestList;
    if ((bestList = wordPairsNext[bestWordPair]) != null && bestList.length > 0 && random.nextDouble() > .05) {
      if (bestWordPair[0] != " ") {
        previousWord = _splitFirst(bestWordPair, " ")[1];
        sentence.addAll(bestWordPair.split(" "));
      } else {
        sentence.add(bestWordPair.substring(1));
        previousWord = "";
      }
    } else {
      bestList = wordsNext[bestWord];
      if (bestList != null) {
        sentence.add(bestWord);
      }
    }

    if (sentence.isEmpty) {
      sentence.add(currentWords[0]);
    }

    var nextWord = sentence.length > 1 ? sentence.last : "";

    var wordPairsTemp = <String, List<int>>{};
    var wordsTemp = <String, List<int>>{};

    for (int size = sentence.length - 1; size < sentence.length; ) {
      size = sentence.length;
      var currentWord = sentence.first;
      var key = currentWord + " " + nextWord;
      var list = wordPairsTemp[key];

      if (list == null) {
        if (wordPairsPrevious[key] != null) {
          wordPairsTemp[key] = new List.from(wordPairsPrevious[key]);
        }
        list = wordPairsTemp[key];
      }

      if (list != null && list.length > 0) {
        int index = random.nextInt(list.length);
        var word = words.get(list[index]).toString();
        list.removeAt(index);
        if (word.isNotEmpty) {
          sentence.addFirst(word);
        }
      } else {
        key = currentWord;
        list = wordsTemp[key];
        if (list == null) {
          if (wordsPrevious[key] != null) {
            wordsTemp[key] = new List.from(wordsPrevious[key]);
          }
          list = wordsTemp[key];
        }

        if (list != null && list.length > 0) {
          var index = random.nextInt(list.length);
          var word = words.get(list[index]).toString();
          list.remove(index);
          if (word.isNotEmpty) {
            sentence.addFirst(word);
          }
        }
      }

      nextWord = currentWord;

    }

    if (sentence.length > 1) {
      previousWord = sentence.toList()[sentence.length - 2];
    }
    
    wordPairsTemp = <String, List<int>>{};
    wordsTemp = <String, List<int>>{};

    for (int size = sentence.length - 1; size < sentence.length; ) {
      size = sentence.length;
      var currentWord = sentence.last;
      var key = previousWord + " " + currentWord;
      var list = wordPairsTemp[key];

      if (list == null) {
        if (wordPairsNext[key] != null) {
          wordPairsTemp[key] = [wordPairsNext[key]];
        }

        list = wordPairsTemp[key];
      }

      if (list != null && list.length > 0) {
        int index = random.nextInt(list.length);
        String word = words.get(list[index]).toString();
        list.removeAt(index);
        if (word.isNotEmpty) {
          sentence.add(word);
        }
      } else {
        key = currentWord;
        list = wordsTemp[key];
        if (list == null) {
          if (wordsNext[key] != null) {
            wordsTemp[key] = new List.from(wordsNext[key]);
          }
          list = wordsTemp[key];
        }

        if (list != null && list.length > 0) {
          var index = random.nextInt(list.length);
          var word = words.get(list[index]).toString();

          list.removeAt(index);

          if (word.isNotEmpty) {
            sentence.add(word);
          }

          var wordFrequency = 1;

          if (wordsNext[word] != null) {
            wordFrequency = words.get(words.lookup(word)).count;
          }

          if (random.nextDouble() > (wordFrequency / sentence.length)) {
            // break;
          }
        }
      }
      previousWord = currentWord;
    }
    
    while (replyString.isEmpty) {
      replyString = sentence.isEmpty ? null : sentence.removeFirst();
    }

    if (replyString.isNotEmpty) {
      replyString = replyString.substring(0, 1).toUpperCase() + replyString.substring(1);
    }
    
    if (replyString.toLowerCase() == name.toLowerCase() && sender.isNotEmpty) {
      replyString = sender;
    }

    for (String replyWord in sentence) {
      if (replyWord.isNotEmpty) {
        replyString += " " + replyWord;
      }
    }

    return allSentences + replyString;
  }

  String randomSentence() {
    String firstWord;
    List<int> list;
    do {
      firstWord = words.get(random.nextInt(words.size)).toString();
      list = wordsNext[firstWord];
    } while (list == null);
    String secondWord = words.get(list[random.nextInt(list.length)]).toString();
    return reply(firstWord + " " + secondWord);
  }

  List<String> _splitFirst(String string, String splitter) {
    int splitIndex = string.indexOf(splitter);
    if (splitIndex != -1) {
      return [string.substring(0, splitIndex), string.substring(splitIndex + 1)];
    } else {
      return [string, ""];
    }
  }

  String _selectivelyLowercase(String it) {
    var lowered = it.toLowerCase();
    if (lowered.startsWith("http:") || lowered.startsWith("https:")) {
      return it;
    } else {
      return lowered;
    }
  }

  void load() {
    var stopwatch = new Stopwatch();
    stopwatch.start();
    File file = new File("data/DCBot/lines.txt");
    if (file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.readAsLinesSync().forEach(addLine);
    stopwatch.stop();
    print("Loaded Lines in ${stopwatch.elapsedMicroseconds} milliseconds");
  }

  void save() {
    var file = new File("data/DCBot/lines.txt");
    var stopwatch = new Stopwatch();
    stopwatch.start();

    file.writeAsStringSync(lines.join("\n"));

    stopwatch.stop();
    print("Saved Lines in ${stopwatch.elapsedMicroseconds} milliseconds");
  }

  List<String> splitMultiple(String input, List<String> by) {
    List<String> strings = [];
    List<String> oldStrings = [];
    oldStrings.add(input);

    for (String sep in by) {
      strings = [];
      for (String current in oldStrings) strings.addAll(current.split(sep));
      oldStrings = strings;
    }

    return strings;
  }
}

class IntMap<L, S> {
  List<S> list = <S>[];
  Map<L, int> map = new Map<L, int>();

  S get(int index) {
    if (index == null) return null;
    return list[index];
  }

  int lookup(L key) {
    return map[key];
  }

  int add(S value, L key) {
    if (map[value] != null) return map[value];
    list.add(value);
    map[key] = list.length - 1;
    return list.length - 1;
  }

  int get size => list.length;
}

class Word {
  String string;
  int count = 1;

  Word(this.string);


  int increment() => count += 1;

  @override
  String toString() => string;
}