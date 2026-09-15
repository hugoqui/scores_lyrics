const controller = require('./mysqlController')
const table = "sermones"
module.exports = {
    getAll: async (req, res) => {
        try {
            const str = `SELECT s.*, p.nombre predicador
            FROM sermones s
            JOIN predicadores p on p.id = s.predicadorId
            ORDER BY s.fecha desc
             `
            const query = await controller.customQuery(str)
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