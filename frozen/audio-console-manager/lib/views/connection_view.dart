import 'package:audio_console_manager/services/demo_osc_service.dart';
import 'package:audio_console_manager/services/osc_service.dart';
import 'package:audio_console_manager/views/console_view.dart';
import 'package:flutter/material.dart';
import 'package:audio_console_manager/models/role.dart';

class ConnectionView extends StatefulWidget {
  const ConnectionView({super.key, required this.selectedRole, this.onLogout});

  final Role selectedRole;
  final VoidCallback? onLogout;

  @override
  State<ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<ConnectionView> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.190');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rol: ${widget.selectedRole.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings_input_component, size: 80, color: Colors.blue),
              const SizedBox(height: 40),
              
              // SECCIÓN 1: CONEXIÓN REAL
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text('Conexión a Consola Real', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección IP de la X32',
                          hintText: 'Ej: 192.168.1.10',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lan),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _connectToReal(context),
                          icon: const Icon(Icons.cast_connected),
                          label: const Text('CONECTAR A IP'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Text('O BIEN', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // SECCIÓN 2: MODO DEMO
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _connectToDemo(context),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('USAR CONSOLA DEMO (Simulación)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectToReal(BuildContext context) async {
    final ipAddress = _ipController.text;
    final oscService = OSCService(ipAddress, 10023);
    
    await oscService.connect();
    
    if (!oscService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se detectó la X32 en esa IP')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ConsoleView(oscService: oscService, selectedRole: widget.selectedRole)
        )
      );
    }
  }

  Future<void> _connectToDemo(BuildContext context) async {
    final demoService = DemoOSCService();
    await demoService.connect();
    
    if (mounted) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ConsoleView(demoOscService: demoService, selectedRole: widget.selectedRole)
        )
      );
    }
  }
}