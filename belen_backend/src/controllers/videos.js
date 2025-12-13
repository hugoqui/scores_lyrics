const controller = require('./mysqlController')
const table = "videos"
module.exports = {
    getAll: async (req, res) => {
        try {
            const str = `SELECT 
            case when v.url LIKE '%https://youtu.be%' 
            then 'youtube' ELSE 'aws' END servidor,	 v.*
            FROM videos v 
            ORDER BY v.id desc`

            const query = await controller.customQuery(str)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

    get: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.findById(table, id)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    find: async (req, res) => {
        try {
            const { text } = req.params
            const query = await controller.getAll(table, "*", 
                `where titulo like '%${text}%'  ORDER BY fecha desc`)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    findByName: async (req, res) => {
        try {
            let { text } = req.params
            text = "%" + text + "%"
            const query = await controller.customQueryWithParams(
                `select * from videos where url like ? limit 1`,
                [text]
            )
            
            res.status(200).json(query[0])
        } catch (error) {
            console.log(error)
            res.status(500).json(error)
        }
    },
       
    create: async (req, res) => {
        try {            
            const query = await controller.create(table, req.body)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

    modify: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.update(table, req.body, id)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    delete: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.delete(table, id)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
}