const bible = require('../controllers/bible')
const songs = require('../controllers/songs')

module.exports = app => {
    //bible
    app.get('/api/books/', bible.getBooks)
    app.get('/api/chapters/:bookId', bible.getChapters)
    app.get('/api/verses/:bookId/:chapter', bible.getVerses)
    app.get('/api/verse/:bookId/:chapter/:verse/:show?', bible.getVerse)
    app.get('/api/search/:text', bible.search)
    app.get('/api/completeBible', bible.getCompleteBible)
    
    //songs
    app.get('/api/songs/', songs.getAll)
    app.get('/api/song/:id', songs.get)
    app.post('/api/song/', songs.create)
    app.put('/api/song/:id', songs.modify)
    app.delete('/api/song/:id', songs.delete)
    app.get('/api/songList', songs.getList)
    app.post('/api/songList', songs.addToList)
    app.delete('/api/songList/:id', songs.removeFromList)
    
    //last song
    app.get('/api/lastSong/', songs.getLast)

        
}