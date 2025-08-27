import { Injectable, signal } from '@angular/core'
import { getString, setString, } from "@nativescript/core/application-settings";
import { SongList } from '../models/songList';

@Injectable({
    providedIn: 'root',
})
export class SongListsService {
    myLists = signal<SongList[]>([])
    constructor() {
        this.getLists()
    }

    getLists() {
        try {
            const strData = getString('my-lists') || null
            if (!strData) throw 'no existen listas'
            console.log('lists str...', strData)

            this.myLists.set(JSON.parse(strData))
        } catch (error) {
            console.log('error al paresear listas!! ', error)
            this.myLists.set([])
        }
    }

    createList(name: string) {
        try {
            const strData = getString('my-lists') || '[]';
            const jsonData: SongList[] = JSON.parse(strData);
            jsonData.push({ name, songs: [] })
            setString('my-lists', JSON.stringify(jsonData))
            this.getLists();
        } catch (error) {
            console.log('error al paresear listas!! ', error)
        }
    }

    removeList(i: number) {
        this.myLists.update(lists => {
            const updated = lists.filter((_, index) => index !== i);
            setString('my-lists', JSON.stringify(updated)); 
            return updated;
        });
    }

}
