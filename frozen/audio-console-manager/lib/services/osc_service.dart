import 'dart:async';
import 'dart:io';
import 'package:osc/osc.dart';

class OSCService {
  late RawDatagramSocket _socket;
  final String _address;
  final int _port;
  bool _isConnected = false;

  final _messageStreamController = StreamController<OSCMessage>.broadcast();
  Stream<OSCMessage> get messageStream => _messageStreamController.stream;

  bool get isConnected => _isConnected;

  OSCService(this._address, this._port);

  Future<void> connect() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      // _socket = await RawDatagramSocket.bind('0.0.0.0', 0);
      _socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            final message = OSCMessage.fromBytes(datagram.data);
            _messageStreamController.add(message);
          }
        }
      });
      _isConnected = true;
      print('Connected to OSC server at $_address:$_port');
    } catch (e) {
      print('Error connecting to OSC server: $e');
      _isConnected = false;
    }
  }

  void send(OSCMessage message) {
    if (_isConnected) {
      final bytes = message.toBytes();
      _socket.send(bytes, InternetAddress(_address), _port);
    } else {
      print('Not connected to OSC server.');
    }
  }

  void disconnect() {
    _socket.close();
    _messageStreamController.close();
    _isConnected = false;
    print('Disconnected from OSC server.');
  }
}
