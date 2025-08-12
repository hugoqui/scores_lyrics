import { Component, NO_ERRORS_SCHEMA, OnInit, effect, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page } from '@nativescript/core'
import { InstrumentsService } from '../../services/instruments.service'
import { ActivatedRoute, Router } from '@angular/router'
import { ScoresDownloaderService } from '../../services/scoresDownloader.service';
import { DownloadedFile } from '../../models/downloadedFile'
import { Instrument } from '~/app/models/instrument'

@Component({
  selector: 'ns-score-list',
  templateUrl: './score-list.component.html',
  styleUrl: './score-list.component.css',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreListComponent implements OnInit {
  songList = signal<DownloadedFile[]>([]);
  instrument = signal<Instrument>(null)

  constructor(
    private page: Page,
    public instrumentsService: InstrumentsService,
    private route: ActivatedRoute,
    private router: Router,
    private scoresDownloaderService: ScoresDownloaderService
  ) {
    effect(() => {
      this.songList()
    })
  }

  ngOnInit(): void {
    try {
      console.log('ScoreListComponent ngOnInit...')
      const id = +this.route.snapshot.params.instrumentId

      this.instrument.set(this.instrumentsService.getInstrument(id))

      this.getSongList(this.instrument().name);
    } catch (error) {
      console.error('Error in ScoreListComponent ngOnInit:', error);
    }
  }

  getSongList(instrument: string): void {
    console.log('getSongList called with instrument:', instrument);
    const files: DownloadedFile[] = this.scoresDownloaderService.getDownloadedFiles(instrument)
    this.songList.set(files)
  }

  goToScore(song: DownloadedFile): void {
    const index = this.songList().findIndex(s => s.localPath === song.localPath);
    this.router.navigate(['/score', index], {
      queryParams: { songs: JSON.stringify(this.songList()) }
    });
  }

}
