import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit,effect } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import * as appSettings from '@nativescript/core/application-settings';
import { Instrument } from '../../models/instrument';
import { ActivatedRoute } from '@angular/router';
import { Page } from '@nativescript/core';
import { InstrumentsService } from '~/app/services/instruments.service';
import { SocketService } from '~/app/services/socket.service';

import { SnackBar } from '@nativescript-community/ui-material-snackbar';


@Component({
  moduleId: module.id,
  selector: 'ns-score',
  templateUrl: 'score.component.html',
  styleUrls: ['score.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent implements AfterViewInit, OnDestroy{
  instrument = signal<Instrument>(null)
  status = signal<'offline' | 'ok' | 'reconnecting' | 'fail'>('offline')
  currentSong = signal<string>('')

  constructor(
    public instrumentsService: InstrumentsService,
    private route: ActivatedRoute,
    private page: Page,
    private socketService: SocketService
  ) {
    effect(() => {
      this.status.set(this.socketService.connectionStatus());
      this.currentSong.set(this.socketService.currentSong());
    });
  }
  ngOnDestroy(): void {
    this.socketService.disconnect()
  }

  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))
  }

  async ngAfterViewInit() {
    try {
      const host = appSettings.getString('host');      
      this.socketService.connect(host);
    } catch (error) {
      console.log('error after init... ', error)
    }
  }

  toggleVisibilityNav() {
    const newStatus = this.page.actionBar.visibility === 'visible' ? 'hidden' : 'visible'    
    this.page.actionBar.visibility = newStatus
    if (newStatus === 'hidden') {
      this.page.actionBar.height = 0
    } else {
      this.page.actionBar.height = 44
    }
  }

  showToast(message: string) {
    console.log("🗨️ Mensaje:", message);
    const snackbar = new SnackBar();
    snackbar.simple(message);
  }

}