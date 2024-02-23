class CommandHistory {
  final List<String> _history = [];
  int _index = 0;

  int get _length => _history.length;

  void add(String command) {
    if (_history.isEmpty || command.compareTo(_history.last) != 0) {
      _history.add(command);
    }
  }

  String? getPrevious() {
    _index--;
    if (_length + _index < 0) {
      _index = 0;
      return null;
    }
    return _history[_length + _index];
  }

  String? getNext() {
    _index++;
    if (_index > 0) {
      _index = -_length;
    }
    if (_index == 0) {
      return null;
    }
    return _history[_length + _index];
  }

  void clear() {
    _history.clear();
    _index = 0;
  }

  void reset() {
    _index = 0;
  }

  @override
  String toString() {
    // print the current state of the history
    // element1 0
    // element2 1
    // element3 2 <- index
    // element4 3

    final sb = StringBuffer();
    sb.writeln('Command History: ${_index + _length} / $_length');
    for (var i = 0; i < _length; i++) {
      sb.writeln(
        '${_history[i]} $i ${i == _index + _length ? '<- index' : ''}',
      );
    }
    return sb.toString();
  }
}
