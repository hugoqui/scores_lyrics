import { AfterViewInit, Component, ElementRef, NO_ERRORS_SCHEMA, OnInit, ViewChild, effect, inject } from '@angular/core'
import { ModalDialogParams, NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

import { signal, computed } from '@angular/core';
import { ScoresDownloaderService } from '~/app/services/scoresDownloader.service';
import { DownloadedFile } from '~/app/models/downloadedFile';
import { TextField } from '@nativescript/core';

@Component({
  moduleId: module.id,
  selector: 'ns-search-modal',
  templateUrl: 'search-modal.component.html',
  styleUrls: ['search-modal.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class SearchModalComponent implements OnInit, AfterViewInit {
  private searchSubject = new Subject<string>();
  cantos: string[] = ['Canto A', 'Canto B', 'Canto X', 'Melodía Y', 'Arreglo Z'];
  searchText = signal('');
  instrument: string;
  private allSongs: DownloadedFile[] = [];
  songList = signal<DownloadedFile[]>([]);
  selectedChord = signal('*')

  @ViewChild('searchInput', { static: true }) searchInput: ElementRef<TextField>;

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

  ngAfterViewInit() {
    setTimeout(() => {
      this.searchInput.nativeElement.focus();
    }, 0);
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
    this.allSongs = this.scoresDownloaderService.getDownloadedFiles(instrument).filter(s => !s.fileName.includes(this.instrument));
    this.applyFilter();
  }

  // Filtra la lista según el filtro de chord
  applyFilter(): void {
    const text = this.searchText().trim().toLowerCase();
    const chord = this.selectedChord();

    let filtered = this.allSongs;

    if (text !== '') {
      filtered = filtered.filter(song => song.fileName.replace('_', ' ').toLowerCase().includes(text));
    }

    if (chord !== '*' && chord !== '') {
      filtered = filtered.filter(song => song.chord?.toLowerCase() === chord.toLowerCase());
    }

    this.songList.set(filtered);
  }

  selectSong(song: DownloadedFile) {
    this.params.closeCallback(song.fileName.replace('.png', ''));
  }

  selecFilter(chordFilter: string) {
    this.selectedChord.set(chordFilter);
    this.applyFilter();
  }

}