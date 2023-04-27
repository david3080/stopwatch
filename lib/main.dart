import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerModel(),
      child: MaterialApp(
        home: StopwatchApp(),
      ),
    ),
  );
}

// ストップウォッチアプリのメイン画面
class StopwatchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ストップウォッチアプリ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('測定中',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: TimingList(stopped: false)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('測定終了',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: TimingList(stopped: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TimerModel>().resetTimers(),
        child: Icon(Icons.refresh),
      ),
    );
  }
}

// 計測中または停止中のタイマーのリスト
class TimingList extends StatefulWidget {
  final bool stopped;

  TimingList({required this.stopped});

  @override
  _TimingListState createState() => _TimingListState();
}

class _TimingListState extends State<TimingList> {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<TimerModel>();

    List<TimerInstance> timersToShow = [];

    if (widget.stopped) {
      timersToShow = model.timers.where((timer) => timer.stopped).toList();
      timersToShow.sort(
          (a, b) => a.elapsedMilliseconds.compareTo(b.elapsedMilliseconds));
    } else {
      timersToShow = model.timers.where((timer) => !timer.stopped).toList();
    }

    return ListView.builder(
      key: Key(widget.stopped.toString()),
      itemCount: timersToShow.length,
      itemBuilder: (_, index) => ChangeNotifierProvider.value(
          value: timersToShow[index],
          child: TimingItem(
              index: model.timers.indexOf(timersToShow[index]),
              stopped: widget.stopped)),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
    );
  }
}

// タイマーのリストアイテム
class TimingItem extends StatelessWidget {
  final int index;
  final bool stopped;

  TimingItem({required this.index, required this.stopped});

  @override
  Widget build(BuildContext context) {
    TimerInstance timer = context.watch<TimerInstance>();

    return Visibility(
      visible: true,
      child: ListTile(
        leading: Text('${index + 1}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        title: Text(timer.elapsedTime,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: timer.started && !timer.stopped
                  ? () => context.read<TimerModel>().stopTimer(timer)
                  : null,
              child: Text('Stop'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: timer.started ? null : timer.start,
              child: Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

// タイマーの状態管理
class TimerModel with ChangeNotifier {
  List<TimerInstance> timers = List.generate(3, (_) => TimerInstance());

  // タイマーが停止されたことを通知
  void stopTimer(TimerInstance timer) {
    timer.stop();
    notifyListeners();
  }

  // タイマーをリセット
  void resetTimers() {
    timers.forEach((timer) => timer.reset());
    notifyListeners();
  }
}

// 個々のタイマーインスタンス
class TimerInstance with ChangeNotifier {
  Timer? _timer;
  Stopwatch _stopwatch = Stopwatch();

  bool get stopped => _stopped;
  bool _stopped = false;

  bool get started => _started;
  bool _started = false;

  String get elapsedTime => _elapsedTime;
  String _elapsedTime = '0';

  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  // タイマーを開始
  void start() {
    _started = true;
    _stopped = false;
    _timer = Timer.periodic(Duration(milliseconds: 100), _onTimer);
    _stopwatch.start();
    notifyListeners();
  }

  // タイマーを停止
  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _stopped = true;
    notifyListeners();
  }

  // タイマーのコールバック処理
  void _onTimer(Timer timer) {
    _elapsedTime = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
    notifyListeners();
  }

  // タイマーをリセット
  void reset() {
    stop();
    _stopwatch.reset();
    _stopped = false;
    _started = false;
    _elapsedTime = '0';
    notifyListeners();
  }
}
