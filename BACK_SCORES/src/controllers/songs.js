const controller = require('./mysqlController')
const table = "songs"

const SongModel = require("../data/songModel")

module.exports = {
    getAll: async (req, res) => {
        try {
            const query = await controller.getAll(table, "*", " ORDER BY title")
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

    getLast: async (req, res) => {
        try {
            const fs = require("fs")
            NOMBRE_ARCHIVO = "src/songid.txt";

            fs.readFile(NOMBRE_ARCHIVO, 'utf8', (error, datos) => {
                if (error) throw error;
                console.log("El contenido es: ", datos);
                let jsonResult
                try {
                    jsonResult = JSON.parse(datos)                    
                } catch (error) {
                    jsonResult = {text: '', reference:'', title:''}
                }

                res.status(200).json(jsonResult)
            });

        } catch (error) {
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

    getList: async (req, res) => {
        try {
            console.log("### lista... ")
            res.status(200).json(SongModel.songList)
        } catch (error) {
            console.log(error)
            res.status(500).json(error)
        }
    },

    addToList: async (req, res) => {
        try {
            SongModel.songList.push(req.body)
            io.emit("list_change")
            res.status(200).json({ message: "ok" })
        } catch (error) {
            res.status(500).json(error)
        }
    },

    removeFromList: async (req, res) => {
        try {
            const id = req.params.id
            console.log("delete...", id)
            SongModel.removeFromList(id)
            io.emit("list_change")
            res.status(200).json({ message: "ok" })
        } catch (error) {
            res.status(500).json(error)
        }
    },

    setNewSong: async (req, res) => {
        try {
            const data = req.body
            console.log("new song... ", data)
            io.emit("text_change", data)
            res.status(200).json({ message: "ok" })
        } catch (error) {
            console.log("new son error> ", error)
        }
    }

}