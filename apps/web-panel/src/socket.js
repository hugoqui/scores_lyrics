import { io } from "socket.io-client";

let socket;

export const initSocket = (host) => {
  if (!socket) {
    socket = io(host, {
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      transports: ['websocket'] // Recomendado para evitar problemas de CORS/Parser
    });

    socket.on("connect", () => {
      console.log('✅ Socket conectado con id:', socket.id);
    });
  }
  return socket;
};

// Exportamos una referencia que se llenará después
export default () => socket;