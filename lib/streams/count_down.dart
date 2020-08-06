import 'dart:async';

class CountDown {

  StreamController<String> _controller = StreamController<String>();
  final Duration duration;

  CountDown({this.duration}) {
    int days;
    int hours;
    int minutes;
    int seconds;

    //Get the seconds from the time left
    int secondsLeft = duration.inSeconds;

    Timer.periodic(Duration(seconds: 1), (timer) {
      secondsLeft--;

      //Initialize the rest of the variables
      minutes = secondsLeft ~/ 60;
      hours = minutes ~/ 60;
      days = hours ~/ 24;
      seconds = secondsLeft - (minutes * 60);

      if (minutes == 0 && seconds == 0) {
        timer.cancel();
      }

      //Construct the string
      String time = '';

      if(days != 0) {
        hours -= days * 24;
        time = '${days}d ${hours}h';
      } else if (hours != 0) {
        minutes -= hours * 60;
        time = '${hours}h ${minutes}m';
      } else if(minutes != 0) {
        time = '${minutes}m ${seconds}s';
      } else {
        time = '${seconds}s';
      }

      _controller.sink.add(time);

      //If we are already past zero, stop timer
      if(secondsLeft < 0) {
        _controller.sink.add('0 sec');
        timer.cancel();
      }

    });
  }

  Stream<String> get stream => _controller.stream.asBroadcastStream(); //This might be the problem??
}
