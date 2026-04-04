import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Servicio encargado de la comunicación por WebSockets con el servidor.
class SocketService {
  IO.Socket? _socket;

  // Controladores de flujo para notificar eventos a los Providers
  final _statusController = StreamController<String>.broadcast();
  final _songController = StreamController<String>.broadcast();
  final _listChangeController = StreamController<void>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get songStream => _songController.stream;
  Stream<void> get listChangeStream => _listChangeController.stream;

  void connect(String host) {
    // Si ya existe una conexión, la cerramos antes de abrir una nueva
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    // Configuración del socket
    // Usamos transporte 'websocket' para mayor estabilidad
    _socket = IO.io(host, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(5000)
      .build());

    // Eventos de conexión
    _socket!.onConnect((_) {
      _statusController.add('online');
    });

    _socket!.onDisconnect((_) {
      _statusController.add('offline');
    });

    _socket!.onConnectError((err) {
      _statusController.add('fail');
    });

    _socket!.onReconnecting((_) => _statusController.add('reconnecting'));

    // Escucha de eventos de negocio
    _socket!.on('text_change', (data) {
      if (data != null) {
        if (data is Map && data['title'] != null) {
          _songController.add(data['title'].toString());
        } else if (data is String) {
          _songController.add(data);
        }
      }
    });

    _socket!.on('listChange', (_) {
      _listChangeController.add(null);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _statusController.add('offline');
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _songController.close();
    _listChangeController.close();
    _socket?.dispose();
  }
}