import 'package:new_symphony/data/models/instrument.dart';

class InstrumentsService {
  final List<Instrument> _instruments = [
    Instrument(id: 1, name: 'Piano', path: 'piano', iconPath: 'assets/icons/piano.svg'),
    Instrument(id: 2, name: 'Violín 1', path: 'violin1', iconPath: 'assets/icons/violin.svg'),
    Instrument(id: 3, name: 'Violín 2', path: 'violin2', iconPath: 'assets/icons/violin.svg'),
    Instrument(id: 4, name: 'Trompeta', path: 'trumpet', iconPath: 'assets/icons/trumpet.svg'),
    Instrument(id: 5, name: 'Flauta 1', path: 'flute1', iconPath: 'assets/icons/flute.svg'),
    Instrument(id: 6, name: 'Flauta 2', path: 'flute2', iconPath: 'assets/icons/flute.svg'),
    Instrument(id: 7, name: 'Clarinete 1', path: 'clarinet1', iconPath: 'assets/icons/clarinet.svg'),
    Instrument(id: 8, name: 'Clarinete 2', path: 'clarinet2', iconPath: 'assets/icons/clarinet.svg'),
    Instrument(id: 9, name: 'Viola', path: 'viola', iconPath: 'assets/icons/viola.svg'),
    Instrument(id: 10, name: 'Cello', path: 'cello', iconPath: 'assets/icons/cello.svg'),
  ];

  List<Instrument> instruments() => _instruments;

  Instrument getInstrument(int id) => 
      _instruments.firstWhere((i) => i.id == id, orElse: () => _instruments.first);
}