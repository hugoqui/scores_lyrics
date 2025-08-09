import { io } from "socket.io-client";


const socket = io(localStorage.getItem('host'), {
  reconnection: true,
  reconnectionAttempts: 5,
  reconnectionDelay: 1000,
});

socket.on("connect", () => {  
  console.log('✅ Socket conectado con id:', socket.id);

});

export default socket;
