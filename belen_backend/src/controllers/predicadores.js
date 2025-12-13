const controller = require('./mysqlController')
const table = "predicadores"
module.exports = {
    getAll: async (req, res) => {
        try {
            const query = await controller.getAll(table)
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
}