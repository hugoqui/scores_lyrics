import { Component, effect, NO_ERRORS_SCHEMA, OnInit, signal, Signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { NativeScriptCommonModule, NativeScriptRouterModule, registerElement } from '@nativescript/angular';
import { Page } from '@nativescript/core';
import { map, switchMap, of } from 'rxjs';
import { DownloadedFile } from '~/app/models/downloadedFile';
import { Instrument } from '~/app/models/instrument';
import { Song } from '~/app/models/song';
import { InstrumentsService } from '~/app/services/instruments.service';
import { ScoresDownloaderService } from '~/app/services/scoresDownloader.service';

@Component({
  moduleId: module.id,
  selector: 'app-download-scores',
  templateUrl: 'download-scores.component.html',
  styleUrls: ['download-scores.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class DownloadScoresComponent implements OnInit {
  constructor(public page: Page,
    private scoresDownloaderService: ScoresDownloaderService,
    private route: ActivatedRoute,
    private instrumentsService: InstrumentsService
  ) {
    effect(() => {

    })
  }

  songList = signal<Song[]>([]);
  loading = signal(false);
  percentage = signal(0);
  downloadedFiles = signal([]);
  instrument = signal<Instrument>(null);
  selectedSong = signal<string>('')

  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))
    this.getSongList();
  }

  getSongList(): void {
    this.scoresDownloaderService.getFileNames(this.instrument().path).pipe(
      switchMap(remoteFiles =>
        of(this.scoresDownloaderService.getDownloadedFiles(this.instrument().name)).pipe(
          map(downloadedFiles => {
            const downloadedFileNames = downloadedFiles.map(f => f.fileName);
            
            return remoteFiles
              .map(fileName => {
                const isDownloaded = downloadedFileNames.includes(fileName)
                const chord = isDownloaded? downloadedFiles.find(f=> f.fileName === fileName).chord : 'F'
                return {
                  title: fileName,
                  isDownloaded: downloadedFileNames.includes(fileName),
                  chord
                }
              });
          })
        )
      )
    ).subscribe({
      next: (songList: Song[]) => {
        console.log('songlist...', songList.slice(0, 2))
        this.songList.set(songList);
      },
      error: (error) => console.error('Error combinando listas:', error)
    });
  }

  async downloadSingleSong(title: string): Promise<void> {
    this.loading.set(true)
    this.selectedSong.set(`${title}`)
    console.log('selected song...', this.selectedSong())
    const filePath = await this.scoresDownloaderService.downloadFile(`${title}`, this.instrument().path);
    const chord = await this.scoresDownloaderService.getSongChord(title, this.instrument().path)
    const dowloadedFile: DownloadedFile = {
      instrument: this.instrument().name,
      fileName: `${title}`,
      localPath: filePath,
      chord
    }
    this.scoresDownloaderService.addDownloadedFile(dowloadedFile);
    this.songList.update(list =>
      list.map(song =>
        song.title === `${title}`
          ? { ...song, isDownloaded: true }
          : song
      )
    );
    this.loading.set(false)
  }

  isCanceled = signal<boolean>(false);
  generalLoading = signal(false);
  nScores = signal<number>(0)

  async downloadAllSongs() {
    const isConfirmed = await confirm('Se descargarán 45mb, ¿Desea comenzar la descarga?');
    if (!isConfirmed) { return }

    this.generalLoading.set(true);
    this.isCanceled.set(false);
    this.nScores.set(0)

    for (let i = 0; i < this.songList().length; i++) {
      if (this.isCanceled()) {
        this.generalLoading.set(false)        
      }
      const title: string = this.songList()[i].title;
      await this.downloadSingleSong(title); 
      this.nScores.set(this.nScores() + 1);    
    }

    this.generalLoading.set(false)
  }

  cancelDownload(){
    this.isCanceled.set(true)
  }
}