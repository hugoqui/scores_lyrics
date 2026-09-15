const controller = require('./mysqlController')
const table = "videos"
module.exports = {
    get: async (req, res) => {
        try {            
            const query = await controller.getAll("version")
            res.status(200).json(query[0])
        } catch (error) {
            res.status(500).json(error)
        }
    },
    
    getServers: async (req, res) => {
        try {            
            const query = await controller.getAll("servers")
            console.log("el resultado... ", query)
            res.status(200).json(query[0])
        } catch (error) {
            res.status(500).json(error)
        }
    },
}