import { DownloadedFile } from "./downloadedFile";

export interface SongList{
    name: string;
    instrument: string;
    songs: DownloadedFile[];
}