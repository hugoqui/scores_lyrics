import 'package:new_symphony/data/models/instrument.dart';

class InstrumentsService {
  final List<Instrument> _instruments = [
    Instrument(id: 1, name: 'Piano', path: 'piano', iconPath: 'assets/icons/piano.png'),
    Instrument(id: 2, name: 'Violín 1', path: 'violin1', iconPath: 'assets/icons/violin1.png'),
    Instrument(id: 3, name: 'Violín 2', path: 'violin2', iconPath: 'assets/icons/violin2.png'),
    Instrument(id: 4, name: 'Trompeta', path: 'trumpet', iconPath: 'assets/icons/trumpet.png'),
    Instrument(id: 5, name: 'Flauta 1', path: 'flute1', iconPath: 'assets/icons/flute1.png'),
    Instrument(id: 6, name: 'Flauta 2', path: 'flute2', iconPath: 'assets/icons/flute2.png'),
    Instrument(id: 7, name: 'Clarinete 1', path: 'clarinet1', iconPath: 'assets/icons/clarinet1.png'),
    Instrument(id: 8, name: 'Clarinete 2', path: 'clarinet2', iconPath: 'assets/icons/clarinet2.png'),
    Instrument(id: 9, name: 'Viola', path: 'viola', iconPath: 'assets/icons/viola.png'),
    Instrument(id: 10, name: 'Cello', path: 'cello', iconPath: 'assets/icons/cello.png'),
  ];

  List<Instrument> instruments() => _instruments;

  Instrument getInstrument(int id) => 
      _instruments.firstWhere((i) => i.id == id, orElse: () => _instruments.first);
}