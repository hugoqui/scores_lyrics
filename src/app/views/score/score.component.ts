import { Component, NO_ERRORS_SCHEMA, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import * as appSettings from '@nativescript/core/application-settings';

import { Instrument } from '../../models/instrument';
import { ActivatedRoute } from '@angular/router';
import { Page } from '@nativescript/core';
import { InstrumentsService } from '~/app/services/instruments.service';

import { SnackBar } from '@nativescript-community/ui-material-snackbar';

@Component({
  moduleId: module.id,
  selector: 'ns-score',
  templateUrl: 'score.component.html',
  styleUrls: ['score.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent {
  constructor(
    public instrumentsService: InstrumentsService, 
    private route: ActivatedRoute, 
    private page: Page
  ) {

  }

  instrument = signal<Instrument>(null)
  
  ngOnInit(): void {    
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))    
  }

  toggleVisibilityNav(){
    const newStatus = this.page.actionBar.visibility === 'visible' ? 'hidden' : 'visible'
    this.page.actionBar.visibility = newStatus
  }

  showToast(message: string) {
    const snackbar = new SnackBar();
    snackbar.simple(message);
  }

}