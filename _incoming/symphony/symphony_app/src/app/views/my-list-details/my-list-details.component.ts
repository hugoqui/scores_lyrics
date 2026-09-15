import { Component, NO_ERRORS_SCHEMA, OnInit, ViewContainerRef, computed, inject } from '@angular/core'
import { ActivatedRoute, Router } from '@angular/router';
import { ModalDialogService, NativeScriptCommonModule, NativeScriptRouterModule, RouterExtensions } from '@nativescript/angular'
import { knownFolders, path } from '@nativescript/core';
import { SearchModalComponent } from '~/app/components/search-modal/search-modal.component';
import { DownloadedFile } from '~/app/models/downloadedFile';
import { InstrumentsService } from '~/app/services/instruments.service';
import { ScoresDownloaderService } from '~/app/services/scoresDownloader.service';
import { SongListsService } from '~/app/services/song-lists.service';

@Component({
  moduleId: module.id,
  selector: 'ns-my-list-details',
  templateUrl: 'my-list-details.component.html',
  styleUrls: ['my-list-details.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule,],
  schemas: [NO_ERRORS_SCHEMA],
})
export class MyListDetailsComponent implements OnInit {

  listName!: string;
  instrument: string = '';
  instrumentLabel: string = '';

  songs = computed(() => {
    const list = this.service.myLists().find(l => l.name === this.listName);
    return list ? list.songs : [];
  });

  constructor(
    private route: ActivatedRoute,
    private service: SongListsService,
    private modalService: ModalDialogService,
    private vcRef: ViewContainerRef,
    private router: Router,
    private instrumentsService: InstrumentsService,
    private downloadedScoresService: ScoresDownloaderService,
    private routerExtensions: RouterExtensions
  ) { }

  goBack(): void {
    this.routerExtensions.backToPreviousPage();
  }

  ngOnInit() {
    this.route.paramMap.subscribe(params => {
      this.listName = params.get('listName') || '';
      const list = this.service.myLists().find(l => l.name === this.listName);
      this.instrument = list?.instrument ?? '';
    });

    this.instrumentLabel = this.instrumentsService.instruments().find(i=> i.path === this.instrument).label ?? ''
  }

  async addSong() {
    try {
      const selectedSong = await this.openSearchModal();
      if (!selectedSong) return;

      const selectedScore = this.downloadedScoresService
        .getDownloadedFiles(this.instrument)
        .find(s => s.fileName.replace('.png', '') === selectedSong);

      if (selectedScore) {
        this.service.addSongToList(selectedScore, this.listName);
      }
    } catch (error) {
      console.log('error al agregar canto', error);
    }
  }

  async openSearchModal() {
    return await this.modalService.showModal(SearchModalComponent, {
      viewContainerRef: this.vcRef,
      fullscreen: false,
      context: { instrument: this.instrument }
    });
  }

  removeSong(song: DownloadedFile) {
    this.service.removeSongFromList(song, this.listName);
  }

  goToScore(song: DownloadedFile): void {
    const index = this.songs().findIndex(s => s.instrument === song.instrument && s.fileName === song.fileName);
    this.router.navigate(['/score', index], {
      queryParams: { songs: JSON.stringify(this.songs()) }
    });

  }
}
