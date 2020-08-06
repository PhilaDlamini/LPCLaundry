import 'dart:async';
import 'dart:isolate';

///Creates an isolate to await a duration in the background
class QueueIsolate{

  Isolate _isolate;
  ReceivePort _receivePort;
  SendPort _sendPort; //Helps us send the queue instance to the other isolate
  final Duration duration;
  final Function onFinished;

  QueueIsolate({this.duration, this.onFinished});

  void start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_awaitDuration, _receivePort.sendPort);
    _receivePort.listen((data) {

      //If the data received is a send port, send the queue instance back
      if(_sendPort == null && data is SendPort) {
        _sendPort = data;
        _sendPort.send(duration);
      } else {
        //Else, this data is to tell us we are done waiting. close the isolate
        onFinished();
        stop();
      }
    });
  }

  void stop() {
    if(_isolate != null) {
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  static void _awaitDuration(SendPort sendPort) {
    //The receive port for this isolate
    ReceivePort receivePort = ReceivePort();

    //Firstly, send this isolate's sendPort
    sendPort.send(receivePort.sendPort);

    //When we receive the queue instance from the other isolate
    receivePort.listen((duration) {
      Timer(duration, () {
        sendPort.send('Done');
      });
    });
  }
}