import { Injectable, signal } from '@angular/core';
import { knownFolders, path, File, Folder, } from '@nativescript/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom, map, Observable, single } from 'rxjs';
import { getString, setString, clear } from "@nativescript/core/application-settings";
import { DownloadedFile } from '../models/downloadedFile';
import { InstrumentsService } from './instruments.service';

@Injectable({
    providedIn: 'root',
})
export class ScoresDownloaderService {
    public scores = signal<string[]>([]);
    public loading = signal<boolean>(false);
    public percentage = signal<number>(0);
    public fileNameDownloading = signal<string>('')
    public isCanceled = signal<boolean>(false);
    public scoresUrl = 'https://partituras.iglesiacristianabelen.com'
    public dbSongList = signal<any[]>([]);

    constructor(private http: HttpClient, private instrumentService: InstrumentsService) { }

    getFileNames(instrument: string): Observable<string[]> {
        return this.http.get(`${this.scoresUrl}/${instrument}/`, { responseType: 'text' }).pipe(
            map(html => {
                const regex = /<a href="([^"]+)">/g;
                let matches;
                const files: string[] = [];
                while ((matches = regex.exec(html)) !== null) {
                    const fileName = decodeURIComponent(matches[1]);
                    if (fileName !== '../' && /\.(png|jpe?g|gif)$/i.test(fileName)) {
                        files.push(fileName);
                    }
                }
                return files;
            })
        );
    }

    async getDbSongs(): Promise<void> {
        if (this.dbSongList().length !== 0) { return }
        const req = await fetch('https://api.iglesiacristianabelen.com/api/cantos')
        const res = await req.json()
        this.dbSongList.set(res)
        return
    }

    async downloadFile(fileName: string, instrument: string): Promise<string> {
        try {
            this.fileNameDownloading.set(fileName)
            const url = `${this.scoresUrl}/${instrument}/${encodeURIComponent(fileName)}`;
            console.log('### Descargando desde URL:', url);
            const response = await fetch(url);

            if (!response.ok) throw new Error(`Error al descargar: ${response.statusText}`);

            const arrayBuffer = await response.arrayBuffer();
            const documents = knownFolders.documents();
            const instrumentFolder = documents.getFolder(instrument);
            const filePath = path.join(instrumentFolder.path, fileName.replace('%E2%94%9C%E2%96%92', 'ñ'));

            const file = File.fromPath(filePath);

            // Guardar binario correctamente
            if (global.isIOS) {
                const data = NSData.dataWithBytesLength(arrayBuffer as any, (arrayBuffer as ArrayBuffer).byteLength);
                file.writeSync(data);
            } else {
                const bytes = new Uint8Array(arrayBuffer);
                const javaBytes = Array.create("byte", bytes.length);
                for (let i = 0; i < bytes.length; i++) {
                    javaBytes[i] = bytes[i];
                }

                const outputStream = new java.io.FileOutputStream(filePath);
                outputStream.write(javaBytes);
                outputStream.close();
            }

            console.log(`Archivo guardado en: ${filePath}`);
            return filePath;
        } catch (error) {
            console.error('Error descargando archivo:', error);
            throw error;
        }
    }

    async getSongChord(title: string, instrument: string): Promise<string> {
        try {
            console.log('finding chord... ', title, instrument)
            await this.getDbSongs()

            const a = this.dbSongList().filter(s=> s.title === 'yo_te_exalto')
            console.log('resultado primero... ', a)
            
            const song =
                this.dbSongList()
                    .find(s =>
                        s.title.toLowerCase().replace(/ /g, '_') === title.replace('.png', '') ||
                        s.title.toLowerCase().replace(/ /g, '_') + instrument === title.replace('.png', '') ||
                        s.title.trim().toLowerCase().replace(/ /g, '_') + '_' + instrument === title.replace('.png', '')
                    )

            return song.chord
        } catch (error) {
            console.log('error al obtener tonalidad... ', error)
            return 'F'
        }
    }

    cancelDownloads() {
        this.isCanceled.set(true)
    }

    getAllDownloadedFiles(): DownloadedFile[] {
        const data = getString("downloadedFiles", "[]");
        return JSON.parse(data) as DownloadedFile[];
    }

    getDownloadedFiles(instrument: string): DownloadedFile[] {
        return this.getAllDownloadedFiles().filter(f => f.instrument === instrument);
    }

    addDownloadedFile(file: DownloadedFile): void {
        const allFiles = this.getAllDownloadedFiles();
        allFiles.push(file);
        setString("downloadedFiles", JSON.stringify(allFiles));
    }

    isFileDownloaded(instrument: string, fileName: string): boolean {
        const files = this.getDownloadedFiles(instrument);
        return files.some(f => f.instrument === instrument && f.fileName === fileName);
    }

    async wipeAll(): Promise<void> {
        try {
            // Borrar settings
            clear();
            console.log("✅ Todos los application-settings fueron borrados.");

            // Carpeta principal de documentos
            const documents = knownFolders.documents();

            // Obtener todas las subcarpetas
            const entities = await documents.getEntities();
            const subfolders = entities.filter(e => e instanceof Folder) as Folder[];

            // Obtener nombres de carpetas correspondientes a instrumentos a borrar
            const instruments = this.instrumentService.instruments().map(i => i.path);

            // Filtrar solo las carpetas que correspondan a instrumentos
            const foldersToDelete = subfolders.filter(folder => instruments.includes(folder.name));

            // Borrar solo las carpetas de instrumentos
            for (const folder of foldersToDelete) {
                try {
                    await folder.clear();
                    console.log(`✅ Carpeta ${folder.name} vaciada.`);
                } catch (err) {
                    console.error(`❌ Error al borrar ${folder.name}:`, err);
                }
            }

            console.log("✅ Limpieza de carpetas de instrumentos completada.");

        } catch (error) {
            console.error("❌ Error al limpiar los datos:", error);
        }
    }

}