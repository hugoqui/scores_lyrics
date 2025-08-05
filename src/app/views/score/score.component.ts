import { Component, NO_ERRORS_SCHEMA, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { prompt } from "@nativescript/core/ui/dialogs";
import * as appSettings from '@nativescript/core/application-settings';
import { InstrumentsService } from '../menu/instruments.service';
import { Instrument } from '../menu/instrument';
import { ActivatedRoute } from '@angular/router';

@Component({
  moduleId: module.id,
  selector: 'ns-score',
  templateUrl: 'score.component.html',
  styleUrls: ['score.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent {
  constructor(public instrumentsService: InstrumentsService, private route: ActivatedRoute) {

  }

  instrument = signal<Instrument>(null)
  
  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))
  }
}