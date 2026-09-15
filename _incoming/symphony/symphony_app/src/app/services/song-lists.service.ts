import { Injectable, signal } from '@angular/core'
import { getString, setString, } from "@nativescript/core/application-settings";
import { SongList } from '../models/songList';
import { DownloadedFile } from '../models/downloadedFile';

@Injectable({
    providedIn: 'root',
})
export class SongListsService {
    myLists = signal<SongList[]>([]);

    constructor() {
        this.getLists();
    }

    private saveLists(lists: SongList[]) {
        setString('my-lists', JSON.stringify(lists));
        this.myLists.set(lists);
    }

    getLists() {
        try {
            const strData = getString('my-lists') || null;
            if (!strData) throw 'no existen listas';
            this.myLists.set(JSON.parse(strData));
        } catch (error) {
            console.log('error al parsear listas!! ', error);
            this.myLists.set([]);
        }
    }

    createList(name: string, instrument: string) {
        try {
            const strData = getString('my-lists') || '[]';
            const jsonData: SongList[] = JSON.parse(strData);
            jsonData.push({ name, songs: [], instrument });
            this.saveLists(jsonData);
        } catch (error) {
            console.log('error al parsear listas!! ', error);
        }
    }

    removeList(i: number) {
        this.myLists.update(lists => {
            const updated = lists.filter((_, index) => index !== i);
            this.saveLists(updated);
            return updated;
        });
    }

    getSongsFromList(listName: string): DownloadedFile[] {
        const list = this.myLists().find(l => l.name === listName);
        return list ? list.songs : [];
    }

    addSongToList(song: DownloadedFile, listName: string) {
        const lists = this.myLists();
        const index = lists.findIndex(l => l.name === listName);

        if (index === -1) {
            console.warn(`No existe la lista con nombre: ${listName}`);
            return;
        }

        const updatedLists = [...lists];
        updatedLists[index] = {
            ...updatedLists[index],
            songs: [...updatedLists[index].songs, song],
        };

        this.saveLists(updatedLists);
    }

    removeSongFromList(song: DownloadedFile, listName: string) {
        const lists = this.myLists();
        const index = lists.findIndex(l => l.name === listName);

        if (index === -1) {
            console.warn(`No existe la lista con nombre: ${listName}`);
            return;
        }

        const updatedLists = [...lists];
        updatedLists[index] = {
            ...updatedLists[index],
            songs: updatedLists[index].songs.filter(s => s !== song),
        };

        this.saveLists(updatedLists);
    }
}
