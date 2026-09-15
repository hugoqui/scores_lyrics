import {
  Component,
  NO_ERRORS_SCHEMA,
  OnDestroy,
  OnInit,
  ViewChild,
  effect,
  inject,
  signal,
  NgZone,
} from "@angular/core";
import {
  NativeScriptCommonModule,
  NativeScriptRouterModule,
  RouterExtensions,
} from "@nativescript/angular";
import {
  Page,
  SwipeGestureEventData,
  SwipeDirection,
  knownFolders,
  path,
  File,
  Connectivity,
  Switch,
  Application,
} from "@nativescript/core";
import { ActivatedRoute } from "@angular/router";
import { DownloadedFile } from "~/app/models/downloadedFile";
import { ScoresDownloaderService } from "~/app/services/scoresDownloader.service";
import { InstrumentsService } from "~/app/services/instruments.service";
import { ZoomImageComponent } from "~/app/components/zoom-image/zoom-image.component";
import { HttpClient } from "@angular/common/http";
import {
  TNSPlayer,
  TNSRecorder,
  AudioRecorderOptions,
} from "nativescript-audio";
import { catchError, of } from "rxjs";
import { isAndroid, isIOS } from "@nativescript/core";
import * as socialShare from "@nativescript/social-share";
import { confirm } from "@nativescript/core";

@Component({
  selector: "ns-score",
  templateUrl: "./score.component.html",
  styleUrl: "./score.component.css",
  imports: [
    NativeScriptCommonModule,
    NativeScriptRouterModule,
    ZoomImageComponent,
  ],
  schemas: [NO_ERRORS_SCHEMA],
})
export class ScoreComponent implements OnInit, OnDestroy {
  songs: DownloadedFile[] = [];
  currentIndex = 0;
  audioState = signal({
    hasAudio: false,
    isPlaying: false,
    isLoading: false,
    audioUrl: "",
    audioMode: "arreglo", // 'arreglo' | 'melodia'
  });
  recordingState = signal({
    isRecording: false,
    isPaused: false,
    recordingPath: "", // Ruta donde se guardará el archivo
    hasRecording: false, // Indica si ya existe una grabación hecha (para mostrar botón de compartir)
  });
  scoreType = signal<'melody' | 'arrangement'>('arrangement');

  private _player: TNSPlayer;
  private _recorder: TNSRecorder;
  private http = inject(HttpClient);

  @ViewChild("imageRef", { static: true }) imageRef;
  constructor(
    private page: Page,
    private route: ActivatedRoute,
    private scoresDownloaderService: ScoresDownloaderService,
    private zone: NgZone,
    private instrumentsService: InstrumentsService,
    private routerExtensions: RouterExtensions
  ) {
    this._player = new TNSPlayer();
    this._recorder = new TNSRecorder();
    this._player.debug = false; // Poner en true para más logs
  }

  ngOnInit(): void {
    try {
      console.log("el id parameter...", this.route.snapshot.params["id"]);
      this.currentIndex = +this.route.snapshot.params["id"];
      console.log("ScoreComponent ngOnInit, currentIndex:", this.currentIndex);
      this.songs = JSON.parse(this.route.snapshot.queryParams["songs"] || "[]");
      console.log("ScoreComponent ngOnInit, songs:", this.songs.length);
      this.initializeScoreType();
      this.checkForAudio();
      console.log("after checkForAudio...");
    } catch (error) {
      console.error("Error en ngOnInit:", error);
    }
  }

  ngOnDestroy(): void {
    // Restaurar la UI si estaba en pantalla completa al salir
    if (this.page.actionBarHidden) {
        this.page.actionBarHidden = false;
        if (isAndroid) {
            const activity = Application.android.startActivity || Application.android.foregroundActivity;
            const window = activity.getWindow();
            window.getDecorView().setSystemUiVisibility(0); // 0 = VISIBLE
        } else if (isIOS) {
            UIApplication.sharedApplication.setStatusBarHiddenWithAnimation(false, 1); // 1 = Fade
        }
    }

    // Liberar recursos del reproductor al salir de la vista
    this.disposePlayer();
  }

  goBack(): void {
    this.routerExtensions.backToPreviousPage();
  }

  // Método centralizado para obtener el nombre del archivo según el modo (Melodía/Arreglo)
  baseName: string;
  private getTargetFileName(): string {
    const song = this.songs[this.currentIndex];
    if (!song) return "";
    
    this.baseName = song.fileName.replace('.png', '');
    // Si el nombre base ya tiene el sufijo del instrumento, lo quitamos para tener la raíz
    if (this.baseName.endsWith(`_${song.instrument}`)) {
        this.baseName = this.baseName.replace(`_${song.instrument}`, '');
    }

    if (this.scoreType() === 'melody') {
        return `${this.baseName}.png`;
    } else {
        return `${this.baseName}_${song.instrument}.png`;
    }
  }

  private initializeScoreType() {
    const song = this.songs[this.currentIndex];
    if (!song) return;
    // Si el archivo cargado originalmente tiene el sufijo, iniciamos en modo arreglo
    const isArrangement = song.fileName.includes(`_${song.instrument}`);
    this.scoreType.set(isArrangement ? 'arrangement' : 'melody');
  }

  get scorePath(): string {
    const song = this.songs[this.currentIndex];
    if (!song) return "";

    const documents = knownFolders.documents();
    const instrumentFolder = documents.getFolder(song.instrument);
    
    // Usamos el método centralizado para saber qué archivo buscar
    const targetFileName = this.getTargetFileName();

    const finalPath = path.join(instrumentFolder.path, targetFileName);

    // Verificar existencia y aplicar Fallbacks
    if (!File.exists(finalPath)) {
      // Recuperamos el baseName para el fallback
      let baseName = song.fileName.replace('.png', '');
      if (baseName.endsWith(`_${song.instrument}`)) {
          baseName = baseName.replace(`_${song.instrument}`, '');
      }

      // Si buscábamos arreglo y no está, intentamos mostrar la melodía como respaldo
      if (this.scoreType() === 'arrangement') {
          const melodyPath = path.join(instrumentFolder.path, `${baseName}.png`);
          if (File.exists(melodyPath)) return melodyPath;
      }
      
      // Último recurso: el archivo original que venía en el objeto song
      const originalPath = path.join(instrumentFolder.path, song.fileName);
      if (File.exists(originalPath)) return originalPath;

      console.warn("Archivo no existe en path:", finalPath);
      return "";
    }

    return finalPath;
  }

  checkForAudio(): void {
    // Reseteamos el estado (MODO inicial: 'arreglo' si es arreglo, si no, no importa)
    this.audioState.set({
      hasAudio: false,
      isPlaying: false,
      isLoading: false,
      audioUrl: "",
      audioMode: "arreglo", // Valor por defecto
    });

    const connectionType = Connectivity.getConnectionType();
    if (connectionType === 0) {
      console.log("Sin conexión a internet.");
      return;
    }

    const song = this.songs[this.currentIndex];
    if (!song) return;

    // IMPORTANTE: Usamos el nombre virtual según el scoreType
    const audioFileName = this.getTargetFileName().replace(".png", ".mp3");

    // 1. DETERMINAR SI ES ARREGLO
    const instrumentSuffixes = this.instrumentsService
      .instruments()
      .map((i) => i.path);

    console.log("instrumentos!!!", instrumentSuffixes)
    const foundInstrument = instrumentSuffixes.find((suffix) =>
      audioFileName.includes(`_${suffix}.mp3`)
    );

    if (!foundInstrument) {
      console.log("No es un arreglo.");
      // No es arreglo → solo puede haber melodía base
      const melodyUrl = `https://partituras.iglesiacristianabelen.com/audios/base/${audioFileName}`;

      // Verificar si existe (usando tu función audioExists)
      this.audioExists(melodyUrl).then((exists) => {
        this.zone.run(() => {
          if (exists) {
            this.audioState.update((s) => ({
              ...s,
              hasAudio: true,
              audioUrl: melodyUrl,
              audioMode: "arreglo", // Aunque no sea arreglo, lo dejamos así (no se usará)
            }));
          }
        });
      });
      return;
    }

    console.log("Es un arreglo de:", foundInstrument);

    // 2. SI ES ARREGLO: verificar que exista el audio del arreglo
    const arrangementUrl = `https://partituras.iglesiacristianabelen.com/audios/${foundInstrument}/${audioFileName}`;

    this.audioExists(arrangementUrl).then((exists) => {
      this.zone.run(() => {
        if (exists) {
          this.audioState.update((s) => ({
            ...s,
            hasAudio: true,
            audioUrl: arrangementUrl, // URL del arreglo
            audioMode: "arreglo", // Switch en posición 'arreglo'
          }));
          console.log("✅ Audio de arreglo disponible");
        }
      });
    });
  }

  toggleScoreType() {
    // Limpiamos el reproductor actual para evitar que reproduzca el audio anterior cacheado
    this.disposePlayer();
    this.scoreType() === 'melody' ? this.scoreType.set('arrangement') : this.scoreType.set('melody');
    // Al cambiar la partitura, recargamos la lógica de audio para que coincida con el nuevo contexto
    this.checkForAudio();
  }

  shouldShowScoreSwitch(): boolean {
      const song = this.songs[this.currentIndex];
      if (!song) return false;
      // Ocultar para piano y trompeta (lógica heredada de LiveComponent)
      if (song.instrument === 'piano' || song.instrument === 'trumpet') return false;
      return true;
  }

  // Función que determina si debería mostrarse el switch
  shouldShowAudioSwitch(): boolean {
    // Si estamos viendo la melodía, NO mostramos switch de audio (comportamiento de "canto base")
    if (this.scoreType() === 'melody') return false;

    const song = this.songs[this.currentIndex];
    if (!song) return false;

    // Usamos el nombre virtual
    const audioFileName = this.getTargetFileName().replace(".png", ".mp3");
    const instrumentSuffixes = this.instrumentsService
      .instruments()
      .map((i) => i.path);
    const foundInstrument = instrumentSuffixes.find((suffix) =>
      audioFileName.includes(`_${suffix}.mp3`)
    );

    // Es arreglo si encontramos un instrumento
    const isArrangement = !!foundInstrument;

    // Y además debe tener audio disponible
    return isArrangement && this.audioState().hasAudio;
  }

  private audioExists(url: string): Promise<boolean> {
    return new Promise((resolve) => {
      if (!url) {
        resolve(false);
        return;
      }

      this.http
        .get(url, { observe: "response", responseType: "blob" })
        .pipe(
          catchError(() => {
            resolve(false);
            return of(null);
          })
        )
        .subscribe((response) => {
          resolve(response?.status === 200);
        });
    });
  }

  async toggleAudioMode(): Promise<void> {
    const currentState = this.audioState();

    if (currentState.isPlaying) {
      this.pause();
    }

    this.disposePlayer(); // ← Esta función ya la tienes
    console.log('Player reseteado para cargar nuevo audio');

    const song = this.songs[this.currentIndex];

    if (!song || !currentState.hasAudio) {
      console.log("No hay partitura o no hay audio disponible");
      return;
    }

    // Usamos el nombre virtual
    const audioFileName = this.getTargetFileName().replace(".png", ".mp3");

    // 1. Determinar nuevo modo
    const newMode =
      currentState.audioMode === "arreglo" ? "melodia" : "arreglo";
    console.log(`Cambiando de ${currentState.audioMode} a ${newMode}`);

    // 2. Detener reproducción actual si está sonando
    if (currentState.isPlaying) {
      this.pause();
    }

    // 3. Mostrar indicador de carga
    this.audioState.update((s) => ({ ...s, isLoading: true }));

    let newUrl = "";
    const instrumentSuffixes = this.instrumentsService.instruments().map((i) => i.path);
    const foundInstrument = instrumentSuffixes.find((suffix) =>audioFileName.includes(`_${suffix}.mp3`));

    if (newMode === "arreglo") {
      // Buscar URL del arreglo (ya deberíamos tenerla)
      if (foundInstrument) {
        newUrl = `https://partituras.iglesiacristianabelen.com/audios/${foundInstrument}/${audioFileName}`;
      }
    } else {      
      const melodyFileName = audioFileName.replace(`_${foundInstrument}.mp3`, '.mp3');      
      newUrl = `https://partituras.iglesiacristianabelen.com/audios/base/${melodyFileName}`;
    }

    console.log(`URL de ${newMode}:`, newUrl);

    // 4. Verificar que el nuevo audio exista
    if (newUrl) {
      const exists = await this.audioExists(newUrl);

      this.zone.run(() => {
        if (exists) {
          this.audioState.update((s) => ({
            ...s,
            audioMode: newMode,
            audioUrl: newUrl,
            isLoading: false,
          }));
          console.log(`✅ Modo cambiado a ${newMode}`);
        } else {
          // El audio no existe, revertir al modo anterior
          console.log(`❌ Audio de ${newMode} no disponible`);
          this.audioState.update((s) => ({
            ...s,
            isLoading: false,
          }));
          // Opcional: mostrar alerta al usuario
          alert(
            `El audio de ${
              newMode === "arreglo" ? "arreglo" : "melodía"
            } no está disponible.`
          );
        }
      });
    }
  }

  onAudioModeChange(args: any): void {
    const sw = args.object as Switch;
    const newMode = sw.checked ? "arreglo" : "melodia";

    console.log(`Switch cambiado a ${newMode} (checked: ${sw.checked})`);

    // Solo cambiar si el modo es diferente al actual
    if (this.audioState().audioMode !== newMode) {
      this.toggleAudioMode();
    }
  }

  play(): void {
    const state = this.audioState();
    if (!state.hasAudio || state.isLoading || state.isPlaying) return; // No hacer nada si ya está sonando o cargando

    // Si el audio está cargado (duration > 0), simplemente dale play.
    // Esto funciona para reanudar desde pausa o para empezar desde el principio si fue detenido.
    if (this._player.duration > 0) {
      this._player.play();
      this.audioState.update((s) => ({ ...s, isPlaying: true }));
    } else {
      // Si es la primera vez (o después de un dispose), cargar desde la URL.
      // Mostramos el indicador de carga inmediatamente
      this.audioState.update((s) => ({ ...s, isLoading: true }));

      this._player
        .playFromUrl({
          audioFile: state.audioUrl,
          loop: false,
          completeCallback: () => {
            // Cuando el audio termina, lo marcamos como no reproduciéndose
            this.zone.run(() =>
              this.audioState.update((s) => ({ ...s, isPlaying: false }))
            );
          },
          errorCallback: (err) => {
            console.error("Error reproduciendo audio", err);
            this.zone.run(() =>
              this.audioState.update((s) => ({
                ...s,
                isPlaying: false,
                isLoading: false,
              }))
            );
          },
        })
        .then(() => {
          // Cuando el audio empieza a sonar, actualizamos el estado
          this.zone.run(() =>
            this.audioState.update((s) => ({
              ...s,
              isPlaying: true,
              isLoading: false,
            }))
          );
        })
        .catch((err) => {
          console.error(
            "Error al iniciar la reproducción (promesa rechazada)",
            err
          );
          this.zone.run(() =>
            this.audioState.update((s) => ({ ...s, isLoading: false }))
          );
        });
    }
  }

  pause(): void {
    if (!this._player.isAudioPlaying()) return;
    this._player.pause();
    this.audioState.update((s) => ({ ...s, isPlaying: false }));
  }

  stop(): void {
    // Si no hay nada que detener, no hacemos nada.
    if (this._player.currentTime === 0 && !this._player.isAudioPlaying())
      return;

    // Pausamos la reproducción y la rebobinamos al inicio.
    this._player.pause();
    this._player.seekTo(0);
    this.audioState.update((s) => ({
      ...s,
      isPlaying: false,
      isLoading: false,
    }));
  }

  private disposePlayer(): void {
    if (this._player) {
      this._player.dispose();
      this._player = new TNSPlayer(); // Creamos una nueva instancia limpia.
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
    image
      .animate({
        translate: { x: translateX, y: 0 },
        opacity: 0,
        duration: 200,
      })
      .then(() => {
        // Reset posición para la nueva imagen
        image.translateX = -translateX;
        return image.animate({
          translate: { x: 0, y: 0 },
          opacity: 1,
          duration: 200,
        });
      });
  }

  toggleVisibilityNav() {
    // Invertimos el estado: Si el ActionBar se ve, queremos ocultarlo (Full Screen)
    const goFullScreen = !this.page.actionBarHidden;

    // 1. Controlar el ActionBar (NativeScript maneja la altura automáticamente)
    this.page.actionBarHidden = goFullScreen;

    // 2. Controlar Barra de Estado y Botones de Navegación (Nativo)
    if (isAndroid) {
      const activity = Application.android.startActivity || Application.android.foregroundActivity;
      const window = activity.getWindow();
      const decorView = window.getDecorView();
      
      if (goFullScreen) {
        // Modo Inmersivo Sticky: Oculta Status Bar y Navigation Bar, pero permite sacarlos con un swipe
        // Flags: IMMERSIVE_STICKY (4096) | FULLSCREEN (4) | HIDE_NAVIGATION (2)
        const uiOptions = 4096 | 4 | 2; 
        decorView.setSystemUiVisibility(uiOptions);
      } else {
        // Restaurar visibilidad normal
        decorView.setSystemUiVisibility(0);
      }
    } else if (isIOS) {
      // Ocultar Status Bar en iOS con animación Fade (1)
      const app = UIApplication.sharedApplication;
      app.setStatusBarHiddenWithAnimation(goFullScreen, 1);
    }
  }

  // ... después de tu función stop() ...
  async startRecording(): Promise<void> {
    console.log("Función startRecording() llamada");

    // 1. VERIFICAR ESTADO USANDO NUESTRA SEÑAL (no isRecording())
    const currentState = this.recordingState();
    if (currentState.isRecording || currentState.isPaused) {
      console.log(
        "Ya hay una grabación en curso o pausada. Estado:",
        currentState
      );
      return;
    }

    // 2. Crear un nombre de archivo único para la grabación
    console.log("Creando nombre de archivo único...");
    const song = this.songs[this.currentIndex];
    if (!song) {
      console.error("No hay partitura seleccionada");
      return;
    }

    const baseName = song.fileName.replace(".png", "");
    const timestamp = new Date().getTime();
    const fileName = `${baseName}_grabacion_${timestamp}.m4a`;

    // 3. Definir la ruta donde se guardará
    console.log("Configurando ruta de grabación...");
    const documents = knownFolders.documents();
    const filePath = path.join(documents.path, fileName);
    console.log("Ruta completa:", filePath);

    // 4. Configurar las opciones del grabador
    const options: AudioRecorderOptions = {
      filename: filePath,
      metering: true,
      errorCallback: (errorObject) => {
        console.error("Error callback de grabación:", errorObject);
        this.zone.run(() => {
          this.recordingState.update((s) => ({
            ...s,
            isRecording: false,
            isPaused: false,
          }));
        });
      },
      infoCallback: (infoObject) => {
        console.log("Info callback de grabación:", infoObject);
      },
    };

    console.log("Opciones de grabación definidas:", JSON.stringify(options));

    try {
      // 5. Iniciar la grabación (la promesa se resuelve cuando comienza)
      console.log("Intentando iniciar grabación...");
      await this._recorder.start(options);

      // 6. Actualizar el estado
      console.log("start() completado. Actualizando estado...");
      this.zone.run(() => {
        this.recordingState.update((s) => ({
          ...s,
          isRecording: true,
          isPaused: false,
          recordingPath: filePath,
          hasRecording: false,
        }));
      });

      console.log("✅ Grabación iniciada exitosamente en:", filePath);
    } catch (error) {
      console.error("❌ Error en start():", error);
      // IMPORTANTE: Verifica si el error es de permisos
      if (
        error.toString().includes("permission") ||
        error.toString().includes("PERMISSION")
      ) {
        console.error(
          "Posible problema de permisos. Verifica que los permisos estén configurados."
        );
      }
    }
  }
  async stopRecording(): Promise<void> {
    console.log("Función stopRecording() llamada");

    const currentState = this.recordingState();
    if (!currentState.isRecording && !currentState.isPaused) {
      console.log("No hay grabación activa para detener");
      return;
    }

    try {
      console.log("Deteniendo grabador...");
      const result = await this._recorder.stop();
      console.log("Grabador detenido. Resultado:", result);

      const filePath = currentState.recordingPath;

      // Preguntar SI/NO antes de actualizar el estado
      const userConfirmed = await confirm({
        title: "Compartir grabación",
        message:
          "¿Quieres compartir esta grabación?\n\nSi seleccionas 'No', el archivo se eliminará.",
        okButtonText: "Sí, compartir",
        cancelButtonText: "No, eliminar",
      });

      if (userConfirmed) {
        // Usuario QUIERE compartir
        this.zone.run(() => {
          this.recordingState.update((s) => ({
            ...s,
            isRecording: false,
            isPaused: false,
            hasRecording: true, // Mantiene el archivo para compartir
          }));
        });
        console.log("✅ Grabación lista para compartir. Archivo:", filePath);
        // Llamar a shareRecording automáticamente
        setTimeout(() => this.shareRecording(), 300);
      } else {
        // Usuario NO QUIERE compartir - ELIMINAR archivo
        console.log(
          "Usuario no quiere compartir. Eliminando archivo:",
          filePath
        );
        if (File.exists(filePath)) {
          File.fromPath(filePath).remove();
          console.log("Archivo eliminado");
        }

        // Resetear estado SIN hasRecording
        this.zone.run(() => {
          this.recordingState.update((s) => ({
            ...s,
            isRecording: false,
            isPaused: false,
            hasRecording: false, // No hay archivo
            recordingPath: "", // Limpiar ruta
          }));
        });
        console.log("✅ Grabación descartada");
      }
    } catch (error) {
      console.error("❌ Error al detener la grabación:", error);
    }
  }
  async pauseRecording(): Promise<void> {
    console.log("Función pauseRecording() llamada");

    if (!this.recordingState().isRecording) {
      console.log("No hay grabación activa para pausar");
      return;
    }

    try {
      console.log("Pausando grabación...");
      // 1. Pausar la grabación en el dispositivo
      const result = await this._recorder.pause();
      console.log("Grabación pausada. Resultado:", result);

      // 2. Actualizar el estado
      this.zone.run(() => {
        this.recordingState.update((s) => ({
          ...s,
          isRecording: false,
          isPaused: true, // Estado clave: está pausada
        }));
      });

      console.log("✅ Grabación pausada");
    } catch (error) {
      console.error("❌ Error al pausar la grabación:", error);
    }
  }
  async resumeRecording(): Promise<void> {
    console.log("Función resumeRecording() llamada");

    if (!this.recordingState().isPaused) {
      console.log("No hay grabación pausada para reanudar");
      return;
    }

    try {
      console.log("Reanudando grabación...");
      // 1. Reanudar la grabación en el dispositivo
      // NOTA: nativescript-audio usa resume() para reanudar
      const result = await this._recorder.resume();
      console.log("Grabación reanudada. Resultado:", result);

      // 2. Actualizar el estado
      this.zone.run(() => {
        this.recordingState.update((s) => ({
          ...s,
          isRecording: true,
          isPaused: false,
        }));
      });

      console.log("✅ Grabación reanudada");
    } catch (error) {
      console.error("❌ Error al reanudar la grabación:", error);
    }
  }

  async shareRecording(): Promise<void> {
    console.log("Función shareRecording() llamada");

    const currentState = this.recordingState();

    // 1. Verificar que haya un archivo grabado
    if (!currentState.hasRecording || !currentState.recordingPath) {
      console.error(
        "❌ No hay una grabación para compartir. Estado:",
        currentState
      );
      alert("Primero debes grabar y detener una grabación.");
      return;
    }

    // 2. Verificar que el archivo exista físicamente
    const filePath = currentState.recordingPath;
    console.log("Verificando existencia del archivo:", filePath);

    if (!File.exists(filePath)) {
      console.error(
        "❌ El archivo de grabación no existe en la ruta:",
        filePath
      );
      alert(
        "El archivo de grabación no se encontró. Intenta grabar nuevamente."
      );
      return;
    }

    console.log(
      "✅ Archivo verificado. Tamaño:",
      File.fromPath(filePath).size,
      "bytes"
    );

    // 3. Preparar datos para compartir
    const song = this.songs[this.currentIndex];
    const baseName = song?.fileName.replace(".png", "") || "Partitura";
    const shareText = `Mi práctica de "${baseName}" - grabada con Symphony App`;

    try {
      console.log("Preparando para compartir...");

      // Compartir usando sharePdf (funciona para cualquier archivo)
      const file = File.fromPath(filePath);
      await socialShare.sharePdf(file, "Compartir grabación", shareText);

      console.log("✅ Compartido exitosamente");
    } catch (error) {
      console.error("❌ Error al compartir:", error);

      if (
        error.toString().includes("cancel") ||
        error.toString().includes("Cancelled")
      ) {
        console.log("Usuario canceló el compartir");
      } else {
        alert(
          "No se pudo compartir la grabación. Verifica que tengas una app para compartir archivos."
        );
      }
    }
  }
}
