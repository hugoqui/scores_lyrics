import { Component, NO_ERRORS_SCHEMA, inject, signal, OnDestroy, AfterViewInit, effect, ViewContainerRef, ViewChild, TRANSLATIONS } from '@angular/core'
import { ModalDialogService, NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import * as appSettings from '@nativescript/core/application-settings';
import { Instrument } from '../../models/instrument';
import { ActivatedRoute } from '@angular/router';
import { knownFolders, Page, path, File, SwipeGestureEventData, SwipeDirection } from '@nativescript/core';
import { InstrumentsService } from '~/app/services/instruments.service';
import { SocketService } from '~/app/services/socket.service';
import { SearchModalComponent } from '~/app/components/search-modal/search-modal.component';
import { SnackBar } from '@nativescript-community/ui-material-snackbar';
import { HttpClient } from '@angular/common/http';
import { Subscription } from 'rxjs';

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
  worshipList = signal<string[]>([]);
  workingOffline = signal<boolean>(false);
  private listChangeSubscription: Subscription;
  @ViewChild('imageRef', { static: true }) imageRef;

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
      console.log("!!!!!!!!!!!!!!! el primer effect lanzado")
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
        } else {
          this.scorePath.set('');
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
      console.log("!!!!!!!!!!!!!!! el segundo effect lanzado")
      this.status.set(this.socketService.connectionStatus());
      this.currentSong.set(this.socketService.currentSong());
    });
  }


  ngOnDestroy(): void {
    this.turnOffSocket()
  }

  ngOnInit(): void {
    const id = +this.route.snapshot.params.id
    this.instrument.set(this.instrumentsService.getInstrument(id))
  }

  turnOffSocket() {
    this.socketService.disconnect()
    if (this.listChangeSubscription) {
      this.listChangeSubscription.unsubscribe();
    }
  }

  async ngAfterViewInit() {
    try {
      const host = appSettings.getString('host');
      this.socketService.connect(host);
      this.listChangeSubscription = this.socketService.onListChange().subscribe(() => {
        this.getWorshipList();
      });

      this.getWorshipList(); // carga inicial

      setTimeout(() => {
        this.getLastSong();
      }, 500);
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
        const updatedList = [...this.worshipList(), selectedSong];
        this.worshipList.set(updatedList);
      }
    });
  }

  getLastSong() {
    const host = appSettings.getString('host')
    const url = `${host}/api/lastSong`
    this.httpClient.get<any>(url).subscribe(
      res => {
        if (!(res && res.tile)) return
        const title = res.title.replace(/ /g, '_').toLowerCase();
        this.currentSong.set(title)
      },
      err => {
        console.error('!!!!! Error en GetlastSong :', err);
        this.showToast('No se pudo obtener el último canto.');
      }
    )
  }

  getWorshipList() {
    const host = appSettings.getString('host')
    const url = `${host}/api/songList`
    this.httpClient.get<any>(url).subscribe(
      res => {
        const list = res.map(s => s.title.replace(/ /g, '_').toLowerCase());
        const currentWorshipList = [...this.worshipList()]
        const mergedList = [...new Set([...list, ...currentWorshipList])];
        this.worshipList.set(mergedList)
        console.log('songs...', this.worshipList().length)
      },
      err => {
        console.error('!!!!! Error en GetWorship :', err);
        this.showToast('No se pudo obtener el listado.');
      }
    )
  }

  onSwipe(args: SwipeGestureEventData) {
    let currentIndex = this.worshipList().findIndex(s => s === this.currentSong());
    let newIndex = currentIndex;

    if (args.direction === SwipeDirection.left && currentIndex < this.worshipList().length - 1) {
      newIndex = currentIndex + 1;
      this.animateSwipe(-300);
    } else if (args.direction === SwipeDirection.right && currentIndex > 0) {
      newIndex = currentIndex - 1;
      this.animateSwipe(300);
    }

    if (newIndex !== currentIndex) {
      const title = this.worshipList()[newIndex];
      console.log('Nuevo canto:', title);
      this.currentSong.set(title);
    }
  }

  animateSwipe(translateX: number) {
    const image = this.imageRef.nativeElement; // referencia al <Image>
    image.animate({
      translate: { x: translateX, y: 0 },
      opacity: 0,
      duration: 200
    }).then(() => {
      // Reset posición para la nueva imagen
      image.translateX = -translateX;
      return image.animate({
        translate: { x: 0, y: 0 },
        opacity: 1,
        duration: 200
      });
    });
  }
}