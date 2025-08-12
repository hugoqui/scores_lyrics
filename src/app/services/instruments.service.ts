import { Injectable, signal } from '@angular/core'
import { Instrument } from '../models/instrument'

@Injectable({
  providedIn: 'root',
})

export class InstrumentsService {
  instruments = signal<Instrument[]>([
    { id: 1, label: 'Piano / Órgano', path: 'piano', name: 'piano'},
    { id: 2, label: 'Violin 1', path: 'violin1', name: 'violin'  },
    { id: 3, label: 'Violin 2', path: 'violin2', name: 'violin'  },
    { id: 4, label: 'Flauta 1', path: 'flute1',  name: 'flute' },
    { id: 5, label: 'Flauta 2', path: 'flute2',  name: 'flute' },
    { id: 6, label: 'Trompeta', path: 'trumpet',  name: 'trumpet' },
    { id: 8, label: 'Clarinete 1', path: 'clarinet1',  name: 'clarinet' },
    { id: 9, label: 'Clarinete 2', path: 'clarinet2',  name: 'clarinet' },
    { id: 10, label: 'Viola', path: 'viola', name: 'viola' },
    { id: 11, label: 'Cello', path: 'cello', name: 'cello' },
  ])

  getInstrument(id: number): Instrument {
    return this.instruments().find((instrument) => instrument.id === id)
  }
}