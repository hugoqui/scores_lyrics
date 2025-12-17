import { Component, NO_ERRORS_SCHEMA, OnDestroy, OnInit, ViewChild, effect, inject, signal, NgZone } from '@angular/core'
import { NativeScriptCommonModule, NativeScriptRouterModule } from '@nativescript/angular'
import { Page, SwipeGestureEventData, SwipeDirection, knownFolders, path, File, Connectivity } from '@nativescript/core'
import { ActivatedRoute } from '@angular/router'
import { DownloadedFile } from '~/app/models/downloadedFile';
import { ScoresDownloaderService } from '~/app/services/scoresDownloader.service';
import { ZoomImageComponent } from '~/app/components/zoom-image/zoom-image.component';
import { HttpClient } from '@angular/common/http';
import { TNSPlayer } from 'nativescript-audio';
import { catchError, of } from 'rxjs';


@Component({
  selector: 'ns-score',
  templateUrl: './score.component.html',
  styleUrl: './score.component.css',
  imports: [NativeScriptCommonModule, NativeScriptRouterModule, ZoomImageComponent],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent implements OnInit, OnDestroy {
  songs: DownloadedFile[] = [];
  currentIndex = 0;
  audioState = signal({ hasAudio: false, isPlaying: false, isLoading: false, audioUrl: '' });

  private _player: TNSPlayer;
  private http = inject(HttpClient);
  
  @ViewChild('imageRef', { static: true }) imageRef;
  constructor(private page: Page, private route: ActivatedRoute, private scoresDownloaderService: ScoresDownloaderService, private zone: NgZone ) {
    this._player = new TNSPlayer();
    this._player.debug = false; // Poner en true para más logs
  }

  ngOnInit(): void {
    try {
      console.log('el id parameter...', this.route.snapshot.params['id'])    
      this.currentIndex = +this.route.snapshot.params['id'];
      console.log('ScoreComponent ngOnInit, currentIndex:', this.currentIndex);
      this.songs = JSON.parse(this.route.snapshot.queryParams['songs'] || '[]');
      console.log('ScoreComponent ngOnInit, songs:', this.songs.length);
      this.checkForAudio();
      console.log('after checkForAudio...')
    } catch (error) {
      console.error('Error en ngOnInit:', error);
    }
  }

  ngOnDestroy(): void {
    // Liberar recursos del reproductor al salir de la vista
    this.disposePlayer();
  }

  get scorePath(): string {
    const song = this.songs[this.currentIndex];
    if (!song) return '';

    const documents = knownFolders.documents();
    const instrumentFolder = documents.getFolder(song.instrument);
    const finalPath = path.join(instrumentFolder.path, song.fileName);

    if (!File.exists(finalPath)) {
      console.warn('Archivo no existe en path:', finalPath);
      return '';
    }
    
    return finalPath;
  }

  checkForAudio(): void {    
    // Reseteamos el estado
    this.audioState.set({ hasAudio: false, isPlaying: false, isLoading: false, audioUrl: '' });
    console.log('Checking for audio availability...');

    const connectionType = Connectivity.getConnectionType();
    console.log('Connection type:', connectionType);
    // Basado en la documentación, ConnectionType.none es 0.
    // Como no podemos importar ConnectionType, comparamos directamente con 0.
    if (connectionType === 0) { // 0 equivale a ConnectionType.none
      console.log('Sin conexión a internet, no se buscará audio.');
      return; // Sin internet, no hay nada que hacer
    }

    const song = this.songs[this.currentIndex];
    if (!song) return;

    const audioFileName = song.fileName.replace('.png', '.mp3');
    const audioUrl = `https://partituras.iglesiacristianabelen.com/audios/base/${audioFileName}`;
    console.log('Verificando existencia de audio en URL:', audioUrl);

    this.http.get(audioUrl, { observe: 'response', responseType: 'blob' }).pipe(
      catchError((error) => {
        console.error('Error en la petición HEAD:', error.message);
        return of(null);
      })
    ).subscribe(response => {
      // Ejecutamos la actualización del estado dentro de NgZone
      this.zone.run(() => {
        if (response && response.status === 200) {
          console.log('Audio disponible en URL! Actualizando estado...');
          this.audioState.set({ hasAudio: true, isPlaying: false, isLoading: false, audioUrl: audioUrl });
        }
      });
    });
  }

  play(): void {
    const state = this.audioState();
    if (!state.hasAudio || state.isLoading || state.isPlaying) return; // No hacer nada si ya está sonando o cargando

    // Si el audio está cargado (duration > 0), simplemente dale play.
    // Esto funciona para reanudar desde pausa o para empezar desde el principio si fue detenido.
    if (this._player.duration > 0) {
      this._player.play();
      this.audioState.update(s => ({ ...s, isPlaying: true }));
    } else {
      // Si es la primera vez (o después de un dispose), cargar desde la URL.
      // Mostramos el indicador de carga inmediatamente
      this.audioState.update(s => ({ ...s, isLoading: true }));

      this._player.playFromUrl({
        audioFile: state.audioUrl,
        loop: false,
        completeCallback: () => {
          // Cuando el audio termina, lo marcamos como no reproduciéndose
          this.zone.run(() => this.audioState.update(s => ({ ...s, isPlaying: false })));
        },
        errorCallback: (err) => {
          console.error("Error reproduciendo audio", err);
          this.zone.run(() => this.audioState.update(s => ({ ...s, isPlaying: false, isLoading: false })));
        }
      }).then(() => {
        // Cuando el audio empieza a sonar, actualizamos el estado
        this.zone.run(() => this.audioState.update(s => ({ ...s, isPlaying: true, isLoading: false })));
      }).catch(err => {
        console.error("Error al iniciar la reproducción (promesa rechazada)", err);
        this.zone.run(() => this.audioState.update(s => ({ ...s, isLoading: false })));
      });
    }
  }

  pause(): void {
    if (!this._player.isAudioPlaying()) return;
    this._player.pause();
    this.audioState.update(s => ({ ...s, isPlaying: false }));
  }

  stop(): void {
    // Si no hay nada que detener, no hacemos nada.
    if (this._player.currentTime === 0 && !this._player.isAudioPlaying()) return;

    // Pausamos la reproducción y la rebobinamos al inicio.
    this._player.pause();
    this._player.seekTo(0);
    this.audioState.update(s => ({ ...s, isPlaying: false, isLoading: false }));
  }

  private disposePlayer(): void {
    if (this._player) {
      this._player.dispose();
    }
  }

  onSwipe(args: SwipeGestureEventData) {
    // Detenemos el audio si se está reproduciendo antes de cambiar de canto
    this.disposePlayer();

    if (args.direction === SwipeDirection.left) {
      if (this.currentIndex < this.songs.length - 1) {
        this.animateSwipe(-300); // hacia la izquierda
        this.currentIndex++;
        this.checkForAudio(); // Verificar audio para la nueva partitura
      }
    } else if (args.direction === SwipeDirection.right) {
      if (this.currentIndex > 0) {
        this.animateSwipe(300); // hacia la derecha
        this.currentIndex--;
        this.checkForAudio(); // Verificar audio para la nueva partitura
      }
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

  toggleVisibilityNav() {
    const newStatus = this.page.actionBar.visibility === 'visible' ? 'hidden' : 'visible'
    this.page.actionBar.visibility = newStatus
    if (newStatus === 'hidden') {
      this.page.actionBar.height = 0
    } else {
      this.page.actionBar.height = 44
    }
  }
}
