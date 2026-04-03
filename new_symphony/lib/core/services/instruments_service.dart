import 'package:new_symphony/data/models/instrument.dart';

class InstrumentsService {
  final List<Instrument> _instruments = [
    Instrument(id: 1, name: 'Piano', path: 'piano'),
    Instrument(id: 2, name: 'Violín', path: 'violin'),
    Instrument(id: 3, name: 'Trompeta', path: 'trumpet'),
    Instrument(id: 4, name: 'Flauta', path: 'flute'),
    Instrument(id: 5, name: 'Clarinete', path: 'clarinet'),
    Instrument(id: 6, name: 'Saxo Alto', path: 'sax_alto'),
    Instrument(id: 7, name: 'Trombón', path: 'trombone'),
    Instrument(id: 8, name: 'Cello', path: 'cello'),
  ];

  List<Instrument> instruments() => _instruments;

  Instrument getInstrument(int id) => 
      _instruments.firstWhere((i) => i.id == id, orElse: () => _instruments.first);
}