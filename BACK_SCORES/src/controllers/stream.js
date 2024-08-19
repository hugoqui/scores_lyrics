module.exports = {
    streamAction: async (req, res) => {
        try {
            
            res.status(200).json(query)
        } catch (error) {
            res.status(500).json(error)
        }
    },

}