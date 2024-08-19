let controller = require('./mysqlController')

module.exports = {
    getBooks: async (req, res) => {
        try {
            const query = await controller.getAll("bible_books")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

    
    getChapters: async (req, res) => {
        try {
            const {bookId} = req.params 
            const query = await controller.getAll("bible_verses", "DISTINCT chapter", "WHERE idBook =" + bookId)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },    
    
    getVerses: async (req, res) => {
        try {
            const {bookId, chapter} = req.params 
            const query = await controller.getAll("bible_verses", "DISTINCT verse", `WHERE idBook = ${bookId} AND chapter=${chapter}`)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },    
   
    getVerse: async (req, res) => {
        try {
            const {bookId, chapter, verse} = req.params 
            const query = await controller.getAll("bible_verses", "text", `WHERE idBook = ${bookId} AND chapter=${chapter} AND verse=${verse}`)
            let result = query[0]
            const book = await controller.findById("bible_books", bookId, "idBook")
            const reference = `${book.name} ${chapter}:${verse}`
            result.reference = reference
            io.emit("text_change", result)
            res.status(200).json(result)
        } catch (error) {
            res.status(500).json(error)
        }
    },    
    
    search: async (req, res) => {
        try {
            const {text} = req.params 
            const str =`select a.text, CONCAT(b.name , ' ', a.chapter, ':',a.verse) reference
            from bible_verses a
            inner join bible_books b on b.idBook = a.idBook
            WHERE text like '%${text}%'
            `
            const query = await controller.customQuery(str)            
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },    
}   