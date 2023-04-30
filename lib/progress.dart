import 'dart:async';

class ProgressBar {
  final int total;
  final _controller = StreamController<int>();

  ProgressBar(this.total);

  Stream<int> get data => _controller.stream;

  void update(int value) {
    _controller.add(value);
  }

  void close() {
    _controller.close();
  }
}