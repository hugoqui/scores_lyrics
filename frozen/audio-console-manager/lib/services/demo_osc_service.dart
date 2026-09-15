import 'dart:async';
import 'package:osc/osc.dart';

/// Simula el comportamiento de OSCService para el modo demo.
class DemoOSCService {
  final _messageStreamController = StreamController<OSCMessage>.broadcast();
  Stream<OSCMessage> get messageStream => _messageStreamController.stream;

  double _faderValue = 0.5;

  Future<void> connect() async {
    // Simula una conexión exitosa instantánea
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void send(OSCMessage message) {
    // Simula el feedback inmediato de la consola
    if (message.address == '/ch/01/mix/fader' && message.arguments.isNotEmpty) {
      _faderValue = message.arguments[0] as double;
      // Simula que la consola responde con el nuevo valor
      _messageStreamController.add(OSCMessage('/ch/01/mix/fader', arguments: [_faderValue]));
    }
  }

  void disconnect() {
    _messageStreamController.close();
  }
}
