import { Component, NO_ERRORS_SCHEMA, OnInit, effect, inject } from '@angular/core'
import { ModalDialogParams, NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

import { signal, computed } from '@angular/core';
import { ScoresDownloaderService } from '~/app/services/scoresDownloader.service';
import { DownloadedFile } from '~/app/models/downloadedFile';

@Component({
  moduleId: module.id,
  selector: 'ns-search-modal',
  templateUrl: 'search-modal.component.html',
  styleUrls: ['search-modal.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class SearchModalComponent implements OnInit {
  private searchSubject = new Subject<string>();
  cantos: string[] = ['Canto A', 'Canto B', 'Canto X', 'Melodía Y', 'Arreglo Z'];
  searchText = signal('');
  instrument: string;
  private allSongs: DownloadedFile[] = [];
  songList = signal<DownloadedFile[]>([]);


  constructor(private scoresDownloaderService: ScoresDownloaderService, private params: ModalDialogParams) {

    if (params.context?.instrument) {
      this.instrument = params.context.instrument
    }

    this.searchSubject.pipe(
      debounceTime(300)
    ).subscribe(value => {
      console.log('searching...', value)
      this.searchText.set(value);
    });

    effect(() => {
      this.searchText()
      this.applyFilter()
    })
  }

  ngOnInit(): void {
    this.getSongList(this.instrument)
  }

  onSearchChange(args) {
    const value = args.value.toLowerCase();
    this.searchSubject.next(value);
  }

  filteredSongs = computed(() => {
    const term = this.searchText().toLowerCase();
    return this.cantos.filter(canto => canto.toLowerCase().includes(term));
  });

  getSongList(instrument: string): void {
    console.log('#### getting songs for ', instrument);
    this.allSongs = this.scoresDownloaderService.getDownloadedFiles(instrument).filter(s=> !s.fileName.includes(this.instrument));
    this.applyFilter();
  }

  // Filtra la lista según el filtro de chord
  applyFilter(): void {
    if (this.searchText().trim() === '') {
      this.songList.set(this.allSongs);
    } else {
      const filtered = this.allSongs.filter(song => song.fileName.replace('_', ' ').includes(this.searchText().toLowerCase()));
      this.songList.set(filtered);
    }
    console.log('filtrados...', this.songList().length)
  }

  selectSong(song: DownloadedFile) {
    this.params.closeCallback(song.fileName.replace('.png', ''));
  }

}