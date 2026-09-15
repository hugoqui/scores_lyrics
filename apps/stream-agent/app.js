const { io } = require("socket.io-client");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");

// process.cwd() busca en la carpeta donde esté guardado el .exe
const configPath = path.join(process.cwd(), "config.json");
let serverUrl = "http://192.168.5.1:3014"; 

// 1. Manejar la configuración (IP dinámica)
if (fs.existsSync(configPath)) {
    // Si existe el archivo, leemos la IP de ahí
    const config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
    if (config.url) serverUrl = config.url;
} else {
    // Si no existe, lo creamos con la IP por defecto para que el usuario lo vea
    fs.writeFileSync(configPath, JSON.stringify({ url: serverUrl }, null, 2));
    console.log("Archivo config.json creado. Puedes editarlo para cambiar la IP.");
}

console.log(`Conectando al servidor en: ${serverUrl}...`);

// 2. Conectar al socket
const socket = io(serverUrl);

socket.on("connect", () => {
    console.log("¡Conexión exitosa con el servidor!");
});

// 3. Escuchar tu evento específico
socket.on("stream_action_to_client", (key) => {
    console.log(`Evento recibido. Simulando tecla: ${key}`);
    
    // 4. El truco: Usar Windows nativo para simular la tecla sin librerías pesadas
    const psCommand = `$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('${key}')`;
    
    exec(`powershell.exe -Command "${psCommand}"`, (error) => {
        if (error) {
            console.error("Error al intentar simular la tecla:", error);
        }
    });
});

socket.on("disconnect", () => {
    console.log("Desconectado del servidor. Intentando reconectar...");
});

socket.on("connect_error", (err) => {
    console.log(`Error de conexión: Verifica que el servidor esté encendido. (${err.message})`);
});