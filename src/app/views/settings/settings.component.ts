import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit, effect } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { knownFolders, Page, path } from '@nativescript/core'
import { InstrumentsService } from '../../services/instruments.service'
import { ScoresDownloaderService } from '../../services/scoresDownloader.service'
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
    this.scoresDownloaderService.downloadScores(item.path);
  }

  getDownloadsLength(instrumentPath: string): number {
    try {
      const documents = knownFolders.documents();
      const instrumentFolder = documents.getFolder(instrumentPath);
      return instrumentFolder.getEntitiesSync().length;      
    } catch (error) {
      return 0
    }
  }
}