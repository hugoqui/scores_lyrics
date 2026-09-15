const controller = require('./mysqlController')
const table = "preguntas pr"
module.exports = {
    getAll: async (req, res) => {
        try {
            const str = `
            SELECT p.*, concat(puntoInterrupcion, restoPregunta) preguntaCompleta,  
            @rownum := @rownum + 1 AS i 
            FROM preguntas p, (SELECT @rownum := 0) r  
            order by p.id asc;`

            const query = await controller.customQuery(str)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    getSpecialList: async (req, res) => {
        try {
            const query = await controller.getAll
                            (table, 
                                "concat(pr.puntoInterrupcion, pr.restoPregunta) preguntaCompleta,  pr.*",
                                "where activo = 1 AND numero IN (44,93,100,99,102,82,101,98,103,92)")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

    get: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.findById(table, id, "numero")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    find: async (req, res) => {
        try {
            const { text } = req.params
            const query = await controller.getAll(table,
                "concat(pr.puntoInterrupcion, pr.restoPregunta) preguntaCompleta,  pr.*", 
                `where CONCAT(pr.puntoInterrupcion, pr.restoPregunta, '', pr.respuesta) like '%${text}%' and activo = 1 ORDER BY Numero`)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
       
    create: async (req, res) => {
        try {            
            const query = await controller.create("preguntas", req.body)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

    modify: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.update("preguntas", req.body, id, "numero")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    delete: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.delete("preguntas", id)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
}