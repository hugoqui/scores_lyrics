'use strict'

const express = require('express')
const app = express()
const morgan = require('morgan')
const bodyParser = require('body-parser')

//cors
const cors = (req, res, next) => {
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    res.header('Access-Control-Allow-Credentials', 'true');
    next();
};

app.use(morgan('dev'))
app.use(bodyParser.json())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(express.static('public'))
app.use(cors)

let PORT = process.env.PORT || 3014
const http = require('http')
const server = http.createServer(app)

server.listen(PORT, () => console.log(`Listening on ${PORT}`))
// process.env.DEBUG = 'socket.io*';

const io = require('socket.io')(server, {
  pingInterval: 25000,
  pingTimeout: 30000,
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
});



global.io = io;
// setInterval(() => io.emit('time',  `${new Date().getHours()}:${new Date().getMinutes()}:${new Date().getSeconds()}` ), 30 * 1000)

io.on('connection', (socket) => { 

    console.log('🥳🥳🥳🥳🥳 Client connected....');
    socket.on('disconnect', (reason) =>   console.log(`Client disconnected. Reason: ${reason}`))
    
    socket.on("song_change", data => {
        console.log("song changed.... ", data)
        io.emit("text_change", data)
        var fs = require('fs')        
        fs.writeFile('src/songid.txt', data.title, function (err) {
            if (err) {
                console.log(err)
            }
        })
    })

    socket.on("text_change", data => {
        console.log("verse changed... ", data)
        io.emit("text_change", data)
    })

    socket.on("streamActionToServer", data => {
        console.log("stream action on server... ", data)
        io.emit("stream_action_to_client", data)
    })
    
    socket.on("scroll_down_to_server", () => {
        console.log("scroll down... ")
        io.emit("scroll_down")
    })
    
    socket.on("scroll_up_to_server", () => {
        console.log("scroll up... ")
        io.emit("scroll_up")
    })
    
    socket.on("auto_play_on", () => {
        console.log("auto play on... ")
        io.emit("auto_play", true)
    })
    
    socket.on("auto_play_off", () => {
        console.log("auto play off... ")
        io.emit("auto_play", false)
    })
    
    socket.on("change_step_server", (step) => {
        console.log("change step... ", step)
        io.emit("change_step", step)
    })
    
    socket.on("change_size_server", (step) => {
        console.log("change size... ", step)
        io.emit("change_size", step)
    })
    
    socket.on("go_top_server", (step) => {
        io.emit("go_top", step)
    })
    
    socket.on("send_text_server", (text) => {
        console.log("change text... ")
        io.emit("receive_text", text)
    })
})
// routes
require('./routes/routes.js')(app)

let mysql = require("mysql")
let config = require('./config/config')
global.pool = mysql.createPool(config)
console.log('base de datos conectada...')
global.fetch = require("node-fetch");