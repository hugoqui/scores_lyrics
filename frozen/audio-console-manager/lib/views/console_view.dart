import 'dart:async';
import 'package:audio_console_manager/models/role.dart';
import 'package:audio_console_manager/services/demo_osc_service.dart';
import 'package:audio_console_manager/services/osc_service.dart';
import 'package:audio_console_manager/widgets/fader.dart';
import 'package:flutter/material.dart';
import 'package:osc/osc.dart';

class ConsoleView extends StatefulWidget {
  final DemoOSCService? demoOscService;
  final OSCService? oscService;
  final Role selectedRole;

  const ConsoleView({
    super.key,
    this.demoOscService,
    this.oscService,
    required this.selectedRole,
  });

  @override
  State<ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<ConsoleView> {
  StreamSubscription<OSCMessage>? _oscSubscription;
  Timer? _xRemoteTimer;

  final int channelCount = 8;
  final List<String> buses = [
    'Main LR',
    ...List.generate(16, (i) => 'Bus ${i + 1}'),
  ];

  late int _selectedBus;
  late List<List<double>> _busFaderValues;

  @override
  void initState() {
    super.initState();
    _selectedBus = widget.selectedRole.busIndex;
    _busFaderValues = List.generate(
      buses.length,
      (_) => List.filled(channelCount, 0.0),
    );

    _setupOscListener();
    _startKeepAlive();

    // Sincronización automática al entrar
    Future.delayed(const Duration(milliseconds: 800), () {
      _requestCurrentValues();
    });
  }

  void _requestCurrentValues() {
    for (int i in widget.selectedRole.visibleChannels) {
      String address = (_selectedBus == 0)
          ? '/ch/${(i + 1).toString().padLeft(2, '0')}/mix/fader'
          : '/ch/${(i + 1).toString().padLeft(2, '0')}/mix/${_selectedBus.toString().padLeft(2, '0')}';

      // Corregido: arguments: [] es obligatorio en esta librería
      final message = OSCMessage(address, arguments: []);
      widget.oscService?.send(message);
      widget.demoOscService?.send(message);
    }
  }

  void _startKeepAlive() {
    widget.oscService?.send(OSCMessage('/xremote', arguments: []));
    _xRemoteTimer = Timer.periodic(const Duration(seconds: 9), (timer) {
      widget.oscService?.send(OSCMessage('/xremote', arguments: []));
    });
  }

  void _setupOscListener() {
    final stream =
        widget.oscService?.messageStream ??
        widget.demoOscService?.messageStream;

    _oscSubscription = stream?.listen((message) {
      final parts = message.address.split('/');

      if (parts.length >= 5 && parts[1] == 'ch') {
        final int? chIdx = int.tryParse(parts[2]) != null
            ? int.parse(parts[2]) - 1
            : null;
        if (chIdx == null) return;

        final String target = parts[4];
        if (message.arguments.isNotEmpty && message.arguments[0] is num) {
          final double newValue = (message.arguments[0] as num).toDouble();

          setState(() {
            if (target == 'fader') {
              _busFaderValues[0][chIdx] = newValue;
            } else {
              final int? busIdx = int.tryParse(target);
              if (busIdx != null && busIdx < buses.length) {
                _busFaderValues[busIdx][chIdx] = newValue;
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _oscSubscription?.cancel();
    _xRemoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rol: ${widget.selectedRole.name}'),
            Text(
              _selectedBus == 0
                  ? 'Mezcla: Main LR'
                  : 'Mezcla: Bus $_selectedBus',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.selectedRole.visibleChannels.map((i) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Fader(
                    value: _busFaderValues[_selectedBus][i],
                    onChanged: (newValue) {
                      setState(() {
                        _busFaderValues[_selectedBus][i] = newValue;
                      });

                      String address = (_selectedBus == 0)
                          ? '/ch/${(i + 1).toString().padLeft(2, '0')}/mix/fader'
                          : '/ch/${(i + 1).toString().padLeft(2, '0')}/mix/${_selectedBus.toString().padLeft(2, '0')}';

                      widget.oscService?.send(
                        OSCMessage(address, arguments: [newValue]),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CH ${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
