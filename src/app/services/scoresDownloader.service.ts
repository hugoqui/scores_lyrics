import { Injectable, signal } from '@angular/core';
import { knownFolders, path, File, Folder, } from '@nativescript/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom, map, Observable } from 'rxjs';
import { getString, setString, clear } from "@nativescript/core/application-settings";
import { DownloadedFile } from '../models/downloadedFile';
import { InstrumentsService } from './instruments.service';
import { Instrument } from '../models/instrument';


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

    async downloadScores(instrument: string): Promise<string[]> {
        try {
            this.loading.set(true);
            const files = await firstValueFrom(this.getFileNames(instrument));

            console.log('Archivos a descargar encontrados:', files.length);

            const downloadedFiles: string[] = [];

            for (const file of files) {
                if (this.isCanceled()) { return }

                const percentage = (downloadedFiles.length / files.length) * 100
                this.percentage.set(parseFloat(percentage.toFixed(2)));
                const filePath = await this.downloadFile(file, instrument);
                this.addDownloadedFile({ instrument, fileName: file, localPath: filePath });
                downloadedFiles.push(filePath);
            }

            this.scores.set(downloadedFiles);
            this.loading.set(false);
            return downloadedFiles;
        } catch (error) {
            console.error('Error descargando las partituras:', error);
            this.loading.set(false);
            throw error;
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

    wipeAll(): void {
        try {
            clear();
            console.log("✅ Todos los application-settings fueron borrados.");
            const instruments = this.instrumentService.instruments();           
            
            for (const instrument of instruments) {                
                let downloadsFolder: Folder = knownFolders.documents().getFolder(instrument.name);
        
                downloadsFolder.clear()
                .then(() => {console.log(`✅ Carpeta de ${instrument.name} vaciada.`);})
                .catch(err => {console.error("❌ Error al borrar descargas:", err);});            
                
                downloadsFolder = knownFolders.documents().getFolder(instrument.path);
        
                downloadsFolder.clear()
                .then(() => {console.log(`✅ Carpeta de ${instrument.name} vaciada.`);})
                .catch(err => {console.error("❌ Error al borrar descargas:", err);});            
            }
            

        } catch (error) {
            console.error("❌ Error al limpiar los datos:", error);
        }
    }

}