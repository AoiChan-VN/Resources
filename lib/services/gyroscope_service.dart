import 'package:sensors_plus/sensors_plus.dart';

class GyroscopeService {
  double x = 0;
  double y = 0;

  void start(Function(double x, double y) onUpdate) {
    gyroscopeEvents.listen((event) {
      x = event.x;
      y = event.y;

      onUpdate(x, y);
    });
  }
} 
