import { Injectable, signal } from '@angular/core';
// import { io, Socket } from 'socket.io-client';
import { io, Socket } from 'socket.io-client/dist/socket.io.js';


@Injectable({
  providedIn: 'root',
})
export class SocketService {
  private socket!: Socket;

  connectionStatus = signal<'offline' | 'ok' | 'reconnecting' | 'fail'>('offline');

  connect(url: string): void {
    if (this.socket) {
      this.socket.disconnect();
    }
    console.log("🌐 Conectando a Socket.IO en:", url);

    this.socket = io(url, {
      transports: ['websocket'],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      forceNew: true // Asegura una nueva conexión
    });

    this.socket.on('connect', () => {
      this.connectionStatus.set('ok');
      console.log('✅ Conectado al servidor');
    });

    this.socket.on('disconnect', (reason) => {
      this.connectionStatus.set('offline');
      console.warn('⚠️ Desconectado del servidor:', reason);
    });

    this.socket.on('reconnect_attempt', () => {
      this.connectionStatus.set('reconnecting');
      console.log('🔁 Intentando reconectar...');
    });

    this.socket.on('reconnect', () => {
      this.connectionStatus.set('ok');
      console.log('✅ Reconectado exitosamente');
    });

    this.socket.on('reconnect_error', (err) => {
      this.connectionStatus.set('fail');
      console.error('❌ Error al reconectar:', err);
    });

    this.socket.on('reconnect_failed', () => {
      console.error('❌ Falló la reconexión');
    });

    this.socket.on('text_change', (data) => {
      console.log('📩 Texto recibido:', data);
      if (!data.text) return;

      this.handleTextChange(data);
    });
  }

  private handleTextChange(data: any) {
    console.log("Cambiar el texto a:", data.text);
  }

  send(event: string, payload: any) {
    this.socket?.emit(event, payload);
  }
}
