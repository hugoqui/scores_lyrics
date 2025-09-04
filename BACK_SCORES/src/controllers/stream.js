let controller = require('./mysqlController')

module.exports = {
    getConfig: async (req, res) => {
        try {            
            const query = await controller.getAll("config")
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },
    streamAction: async (req, res) => {
        try {
            
            res.status(200).json("query")
        } catch (error) {
            res.status(500).json(error)
        }
    },

}