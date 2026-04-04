import 'package:flutter/material.dart';
import 'package:new_symphony/core/services/instrument_grid.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/features/download/ui/download_list_screen.dart';
import 'package:new_symphony/features/practice/ui/practice_library_screen.dart';

class InstrumentSelectionScreen extends StatelessWidget {
  final bool isPractice;
  const InstrumentSelectionScreen({super.key, this.isPractice = false});

  @override
  Widget build(BuildContext context) {
    final instruments = getIt<InstrumentsService>().instruments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Instrumento'),
      ),
      body: InstrumentGrid(
        instruments: instruments,
        onInstrumentSelected: (instrument) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isPractice 
                ? PracticeLibraryScreen(instrument: instrument)
                : DownloadListScreen(instrument: instrument),
            ),
          );
        },
      ),
    );
  }
}