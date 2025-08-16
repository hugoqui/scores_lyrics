import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit, effect, ViewContainerRef } from '@angular/core'
import { ModalDialogService, NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import * as appSettings from '@nativescript/core/application-settings';
import { Instrument } from '../../models/instrument';
import { ActivatedRoute } from '@angular/router';
import { knownFolders, Page, path, File } from '@nativescript/core';
import { InstrumentsService } from '~/app/services/instruments.service';
import { SocketService } from '~/app/services/socket.service';
import { SearchModalComponent } from '~/app/components/search-modal/search-modal.component';
import { SnackBar } from '@nativescript-community/ui-material-snackbar';
import { HttpClient } from '@angular/common/http';


@Component({
  moduleId: module.id,
  selector: 'ns-live',
  templateUrl: 'live.component.html',
  styleUrls: ['live.component.css'],
  imports: [NativeScriptCommonModule, NativeScriptRouterModule],
  schemas: [NO_ERRORS_SCHEMA],
})
export class LiveComponent implements AfterViewInit, OnDestroy {
  instrument = signal<Instrument>(null)
  status = signal<'offline' | 'online' | 'reconnecting' | 'fail'>('offline')
  currentSong = signal<string>('')
  scorePath = signal<string>('')
  scoreType = signal<'melody' | 'arrangement'>('melody')

  constructor(
    public instrumentsService: InstrumentsService,
    private route: ActivatedRoute,
    private page: Page,
    private socketService: SocketService,
    private modalService: ModalDialogService,
    private vcRef: ViewContainerRef,
    private httpClient: HttpClient
  ) {
    // efecto SOLO para scorePath (no cambies status ni currentSong aquí)
    effect(() => {
      if (this.instrument()) {
        this.getLastSong();
      }

      const instrument = this.instrument();
      const currentSong = this.currentSong();
      const scoreType = this.scoreType();

      if (!currentSong || !instrument) {
        this.scorePath.set('');
        return;
      }

      const documents = knownFolders.documents();
      const instrumentFolder = documents.getFolder(instrument.path);
      const fileName = `${currentSong}.png`;
      const filePath = path.join(instrumentFolder.path, fileName);
      const melodyExists = File.exists(filePath);

      if (scoreType === 'melody') {
        if (melodyExists) {
          const imgFile = File.fromPath(filePath);
          this.scorePath.set(imgFile.path);
          console.log(imgFile.path);
        } else {
          this.scorePath.set('');
          console.log("No existe el archivo:", filePath);
        }
        return;
      }

      // arreglo
      const fileNameArrangement = `${currentSong}_${instrument.path}.png`;
      const filePathArrangement = path.join(instrumentFolder.path, fileNameArrangement);
      const arrangementExists = File.exists(filePathArrangement);
      if (arrangementExists) {
        const imgFile = File.fromPath(filePathArrangement);
        this.scorePath.set(imgFile.path);
      } else if (melodyExists) {
        const imgFile = File.fromPath(filePath);
        this.scorePath.set(imgFile.path);
      } else {
        this.scorePath.set('');
        console.log("No existe el archivo:", filePath);
      }
    });

    // efecto para sockets
    effect(() => {
      this.status.set(this.socketService.connectionStatus());
      this.currentSong.set(this.socketService.currentSong());
    });
  }


  ngOnDestroy(): void {
    this.socketService.disconnect()
  }

  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))
  }

  async ngAfterViewInit() {
    try {
      const host = appSettings.getString('host');
      this.socketService.connect(host);
    } catch (error) {
      console.log('error after init... ', error)
    }
  }

  toggleVisibilityNav() {
    const newStatus = this.page.actionBar.visibility === 'visible' ? 'hidden' : 'visible'
    this.page.actionBar.visibility = newStatus
    if (newStatus === 'hidden') {
      this.page.actionBar.height = 0
    } else {
      this.page.actionBar.height = 44
    }
  }

  showToast(message: string) {
    console.log("🗨️ Mensaje:", message);
    const snackbar = new SnackBar();
    snackbar.simple(message);
  }

  toggleArrangement() {
    this.scoreType() === 'melody' ? this.scoreType.set('arrangement') : this.scoreType.set('melody');
  }

  openSearchModal() {
    this.modalService.showModal(SearchModalComponent, {
      viewContainerRef: this.vcRef,
      fullscreen: false,
      context: {
        instrument: this.instrument().name
      }
    }).then(selectedSong => {
      if (selectedSong) {
        console.log('Canto seleccionado:', selectedSong);
        this.currentSong.set(selectedSong)
      }
    });
  }

  getLastSong() {
    const host = appSettings.getString('host')
    const url = `${host}/api/lastSong`
    this.httpClient.get<any>(url).subscribe(res => {
      const title = res.title.replace(/ /g, '_').toLowerCase();
      this.currentSong.set(title)
    })

  }
}