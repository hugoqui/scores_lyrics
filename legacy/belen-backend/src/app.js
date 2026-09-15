'use strict'

const express = require('express')
const app = express()
const morgan = require('morgan')
const bodyParser = require('body-parser')

//cors
const cors = (req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*')
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    res.header('Access-Control-Allow-Headers', 'Content-Type')
    next()
}

app.use(morgan('dev'))
app.use(bodyParser.json())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(express.static('public'))
app.use(cors)



// let PORT = process.env.PORT || 3014
let PORT =  3014

const server = express()
    .use(app)
    .listen(PORT, () => console.log(`Listening on ${ PORT }`))


require('./routes/routes.js')(app)

let mysql = require("mysql")
let config = require('./config/config')
global.pool = mysql.createPool(config)
console.log('conectado...')
global.fetch = require("node-fetch");