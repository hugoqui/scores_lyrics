import { Injectable, signal } from '@angular/core';
import { SocketIO } from '@triniwiz/nativescript-socketio';


@Injectable({
  providedIn: 'root',
})
export class SocketService {
  private socketIO: any;
  private url: string;
  connectionStatus = signal<'offline' | 'ok' | 'reconnecting' | 'fail'>('offline');

  constructor() {

  }

  connect(url: string): void {
    this.url = url;

    if (!this.socketIO) {
      // this.socketIO = new SocketIO(this.url)
      this.socketIO = new SocketIO(this.url, {
        reconnect: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 2000,
        transports: ['websocket'],
      });

      this.registerListeners();
    }

    if (!this.socketIO.connected) {
      this.socketIO.connect();
      console.log('Intentando conectar socket:', this.url);
    }
  }

  private registerListeners() {
    this.socketIO.on('connect', () => {
      console.log('✅ Connected');
      this.connectionStatus.set('ok');
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
      console.log('Texto recibido:', data);
      this.handleTextChange(data);
    });
  }

  private handleTextChange(data: any) {
    console.log("Cambiar el texto a:", data.text);
  }

  send(event: string, payload: any) {
    this.socketIO.emit(event, payload);
  }

  disconnect() {
    this.socketIO.disconnect();
    console.log('🚪 Disconnected socket');
  }
}
