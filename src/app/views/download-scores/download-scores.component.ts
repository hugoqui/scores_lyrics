import { Component, NO_ERRORS_SCHEMA, OnInit, signal, Signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular';
import { Page } from '@nativescript/core';
import { map, switchMap, of } from 'rxjs';
import { Instrument } from '~/app/models/instrument';
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
    console.log('DownloadScoresComponent initialized');
  }
  
  songList = signal<Song[]>([]);
  loading = signal(false);
  percentage = signal(0);
  isCanceled = signal(false);
  downloadedFiles = signal([]);
  instrument = signal<Instrument>(null);

  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))

    this.getSongList();
  }
  
  getSongList(): void {
    this.scoresDownloaderService.getFileNames(this.instrument().path).pipe(
      switchMap(remoteFiles =>
        of(this.scoresDownloaderService.getDownloadedFiles()).pipe( // wrap in Observable
          map(downloadedFiles => {
            const downloadedFileNames = downloadedFiles.map(f => f.fileName);
            return remoteFiles.map(fileName => ({
              title: fileName,
              localPath: downloadedFileNames.includes(fileName)
                ? downloadedFiles.find(f => f.fileName === fileName).localPath
                : null
            }));
          })
        )
      )
    ).subscribe({
      next: (songList) => {
        this.songList.set(songList);
      },
      error: (error) => console.error('Error combinando listas:', error)
    });
  }

}

interface Song {
  title: string;
  localPath?: string;
}