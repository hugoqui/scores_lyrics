import { Injectable, signal } from '@angular/core';
import { SocketIO } from '@triniwiz/nativescript-socketio';
import { Subject } from 'rxjs';


@Injectable({
  providedIn: 'root',
})
export class SocketService {
  private socketIO: any;
  private url: string;
  connectionStatus = signal<'offline' | 'online' | 'reconnecting' | 'fail'>('offline');
  currentSong = signal<string>('');
  private listChangeSubject = new Subject<void>();

  constructor() { }

  connect(url: string): void {
    this.url = url;

    if (!this.socketIO) {
      this.socketIO = new SocketIO(this.url, {
        reconnect: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 2000,
      });

      this.registerListeners();
    }

    if (!this.socketIO.connected) {
      console.log('Intentando conectar socket:', this.url);
      this.socketIO.connect();
    }
  }

  private registerListeners() {
    this.socketIO.on('connect', () => {
      console.log('✅ Connected');
      this.connectionStatus.set('online');
    });

    this.socketIO.on('disconnect', (reason: string) => {
      console.log('⚠️ Disconnected:', reason);
      this.connectionStatus.set('offline');
    });

    this.socketIO.on('error', (error: any) => {
      console.error('❌ Socket error:', error);
      this.connectionStatus.set('fail');
    });

    this.socketIO.on('connect_error', (error: any) => {
      console.error('❌ Connect error:', error);
    });

    this.socketIO.on('reconnect_attempt', () => {
      console.log('🔁 Reconnecting...');
      this.connectionStatus.set('reconnecting');
    });

    this.socketIO.on('text_change', (data: any) => {
      this.handleTextChange(data);
    });

    this.socketIO.on('list_change', (data: any) => {
      console.log('list change!!!')
      this.listChangeSubject.next();
    });
  }

  onListChange() {
    return this.listChangeSubject.asObservable();
  }

  private handleTextChange(data: any) {
    if (data.reference){
      console.log('includes reference... ')
      return
    }
    const id = this.getIdFromTitle(data.title);
    if (!id) {return}

    this.currentSong.set(id);
    console.log('#####:', id);
  }

  getIdFromTitle(title: string): string {
    try {
      return title.replace(/ /g, '_').toLowerCase();      
    } catch (error) {
      return null
    }
  }

  send(event: string, payload: any) {
    this.socketIO.emit(event, payload);
  }

  disconnect() {
    this.socketIO.disconnect();
    console.log('🚪 Disconnected socket');
  }
}
