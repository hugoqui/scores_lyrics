const controller = require('./mysqlController')
const table = "songs"
module.exports = {
    getAll: async (req, res) => {
        try {
            const query = await controller.getAll(table)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    get: async (req, res) => {
        try {
            const { id } = req.params
            const query = await controller.findById(table, id, "id")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
}