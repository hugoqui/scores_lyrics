import { Injectable, signal } from '@angular/core'
import { Instrument } from '../models/instrument'

@Injectable({
  providedIn: 'root',
})

export class InstrumentsService {
  instrumetns = signal<Instrument[]>([
    { id: 1, label: 'Piano / Órgano', path: '/piano', },
    { id: 2, label: 'Violin 1', path: '/violin', suffix: 1 },
    { id: 3, label: 'Violin 2', path: '/violin', suffix: 2 },
    { id: 4, label: 'Flauta 1', path: '/flute', suffix: 1 },
    { id: 5, label: 'Flauta 2', path: '/flute', suffix: 2 },
    { id: 6, label: 'Trompeta', path: '/trumpet',  },
    { id: 8, label: 'Clarinete 1', path: '/clarinet', suffix: 1 },
    { id: 9, label: 'Clarinete 2', path: '/clarinet', suffix: 2 },
    { id: 10, label: 'Viola', path: '/viola', },
    { id: 11, label: 'Cello', path: '/cello', },
  ])

  getInstrument(id: number): Instrument {
    return this.instrumetns().find((instrument) => instrument.id === id)
  }
}