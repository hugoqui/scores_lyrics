const preguntas = require('../controllers/preguntas')
const videos = require('../controllers/videos')
const version = require('../controllers/version')
const predicadores = require('../controllers/predicadores')
const sermones = require('../controllers/sermones')
const cantos = require('../controllers/cantos')
const usuarios = require('../controllers/usuarios')

module.exports = app => {
    
    //preguntas
    app.get('/api/preguntas_especificas/', preguntas.getSpecialList)
    app.get('/api/preguntas/', preguntas.getAll)
    app.get('/api/preguntas/:id', preguntas.get)
    app.get('/api/preguntas/buscar/:text', preguntas.find)
    app.post('/api/preguntas/', preguntas.create)
    app.put('/api/preguntas/:id', preguntas.modify)
    app.delete('/api/preguntas/:id', preguntas.delete)
    
    //videos
    app.get('/api/videos/', videos.getAll)
    app.get('/api/videos/:id', videos.get)
    app.get('/api/videos/buscar/:text', videos.find)
    app.get('/api/videos/buscarPorNombre/:text', videos.findByName)
    app.post('/api/videos/', videos.create)
    app.put('/api/videos/:id', videos.modify)
    app.delete('/api/videos/:id', videos.delete)

    //version
    app.get('/api/version', version.get)
    app.get('/api/version/getServers', version.getServers)

    //PREDICADORES Y SERMONES
    app.get('/api/predicadores', predicadores.getAll)
    app.get('/api/sermones', sermones.getAll)
    app.get('/api/sermones/:id', sermones.get)
    
    //cantos
    app.get('/api/cantos', cantos.getAll)
    
    //usuarios
    app.post('/api/login', usuarios.login)

}