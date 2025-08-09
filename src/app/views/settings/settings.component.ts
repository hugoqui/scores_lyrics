import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit,effect } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page } from '@nativescript/core'
import {InstrumentsService} from '../../services/instruments.service'
import {ScoresDownloaderService} from '../../services/scoresDownloader.service'
import { Instrument } from '~/app/models/instrument'

@Component({
  moduleId: module.id,
  selector: 'ns-settings',
  templateUrl: 'settings.component.html',
  styleUrls: ['settings.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class SettingsComponent {
  scores = signal<string[]>([]);
  loading = signal<boolean>(false);
  percentage = signal<number>(0);

  constructor(
    private page: Page,
    public instrumentsService: InstrumentsService,
    private scoresDownloaderService: ScoresDownloaderService
  ) {
    effect(() => {
      this.scores.set(this.scoresDownloaderService.scores());
      this.loading.set(this.scoresDownloaderService.loading());
      this.percentage.set(this.scoresDownloaderService.percentage());
    })
  }
  
  downloadScores(item: Instrument): void {
    console.log('Downloading scores...', item)
    const name = (item.path + (item.suffix|| '') ).replace(/\/$/, '');
    this.scoresDownloaderService.downloadScores(name);
    // this.scoresDownloaderService.getFileNames(name).subscribe({
    //   next: (files: string[]) => {
    //     console.log('Files downloaded:', files);
    //     this.scoresDownloaderService.scores.set(files);
    //   },
    //   error: (error) => {
    //     console.error('Error downloading files:', error);
    //   }
    // });
  }
}