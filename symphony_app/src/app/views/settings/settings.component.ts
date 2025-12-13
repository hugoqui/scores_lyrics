import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit, effect } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Dialogs, knownFolders, Page, path } from '@nativescript/core'
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
  selectedId = signal<number>(null);
  instruments = signal<Instrument[]>([]);

  constructor(
    private page: Page,
    private scoreDownloaderService: ScoresDownloaderService,
    public instrumentsService: InstrumentsService,
    private scoresDownloaderService: ScoresDownloaderService
  ) {
    effect(() => {
      this.scores.set(this.scoresDownloaderService.scores());
      this.loading.set(this.scoresDownloaderService.loading());
      this.percentage.set(this.scoresDownloaderService.percentage());
    })
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

  async wipeData() {
    const isConfirmed = await confirm('Se eliminar todos los datos, ¿Desea borrar todos los datos?');
    if (!isConfirmed) { return }

    console.log('Wiping all data...');
    this.scoreDownloaderService.wipeAll();
  }
}