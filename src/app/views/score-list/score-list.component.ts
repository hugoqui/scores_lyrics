import { Component, NO_ERRORS_SCHEMA, OnInit, ViewChild, effect, inject, signal } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Dialogs, Page } from '@nativescript/core'
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
  chordFilter: string = '';
  private allSongs: DownloadedFile[] = [];

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
    this.allSongs = this.scoresDownloaderService.getDownloadedFiles(instrument);
    this.applyFilter();
  }

  goToScore(song: DownloadedFile): void {
    const index = this.songList().findIndex(s => s.fileName === song.fileName && s.instrument === song.instrument);
    this.router.navigate(['/score', index], {
      queryParams: { songs: JSON.stringify(this.songList()) }
    });
  }

  // Filtra la lista según el filtro de chord
  applyFilter(): void {
    if (!this.chordFilter || this.chordFilter === 'Todas') {
      this.songList.set(this.allSongs);
    } else {
      const filtered = this.allSongs.filter(song => song.chord === this.chordFilter);
      this.songList.set(filtered);
    }
  }

  // Método que se llama al cambiar el filtro desde el template
  onFilterChange(newChord: string): void {
    this.chordFilter = newChord;
    this.applyFilter();
  }

  selectFilter() {
    const options = ['Todas', 'C', 'Eb', 'F', 'G', 'Bb'];
    Dialogs.action({
      title: 'Nota',
      message: 'Selecciona la tonalidad:',
      cancelButtonText: 'Cancelar',
      actions: options,
      cancelable: true,
    }).then(selected => {
      console.log("selected!!! ", selected)
      if (selected && selected !== 'Cancelar') {
        this.onFilterChange(selected);
      }
    });

  }

}
