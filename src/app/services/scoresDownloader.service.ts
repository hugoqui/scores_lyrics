import { Injectable, signal } from '@angular/core';
import { knownFolders, path, File, Folder } from '@nativescript/core';

import { HttpClient, HttpResponse } from '@angular/common/http';
import { firstValueFrom, map, Observable } from 'rxjs';
import * as bghttp from 'nativescript-background-http';

@Injectable({
    providedIn: 'root',
})
export class ScoresDownloaderService {
    public scores = signal<string[]>([]);
    public loading = signal<boolean>(false);
    public percentage = signal<number>(0);

    constructor(private http: HttpClient) { }

    private getFileNames(instrument: string): Observable<string[]> {
        return this.http.get(`https://partituras.iglesiacristianabelen.com/${instrument}/`, { responseType: 'text' }).pipe(
            map(html => {
                const regex = /<a href="([^"]+)">/g;
                let matches;
                const files: string[] = [];
                while ((matches = regex.exec(html)) !== null) {
                    const fileName = matches[1];
                    if (fileName !== '../' && /\.(png|jpe?g|gif)$/i.test(fileName)) {                                                
                        files.push(fileName);
                    }
                }
                return files;
            })
        );
    }

    private async downloadFile(url: string, fileName: string, instrument: string): Promise<string> {
        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Error al descargar: ${response.statusText}`);
            
            const arrayBuffer = await response.arrayBuffer();
            const documents = knownFolders.documents();
            const instrumentFolder = documents.getFolder(instrument);
            const filePath = path.join(instrumentFolder.path, fileName.replace('%E2%94%9C%E2%96%92','ñ'));

            // Guarda el archivo
            const file = File.fromPath(filePath);
            await file.writeSync(new Uint8Array(arrayBuffer));

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
                this.percentage.set((downloadedFiles.length / files.length) * 100);
                const filePath = await this.downloadFile(`https://partituras.iglesiacristianabelen.com/${instrument}/${file}`, file, instrument);
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



}