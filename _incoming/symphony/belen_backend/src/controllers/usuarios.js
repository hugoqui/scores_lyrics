const controller = require('./mysqlController')
const jwt = require('jsonwebtoken')
const config = require('../config/config')
module.exports = {
    login: async (req, res) => {
        try {
            const { email, password, device } = req.body
            // escape inputs to avoid sql injection
            const escapedEmail = (email || '').replace(/'/g, "''")
            const escapedPassword = (password || '').replace(/'/g, "''")
            const escapedDeviceId = (device || '').replace(/'/g, "''")
            console.log(`${escapedEmail} and deviceId ${escapedDeviceId}`)

            // La app envía el parámetro `email`, pero la columna en la tabla se llama `username`.
            const str = `SELECT * FROM users WHERE username='${escapedEmail}' AND password=SHA1('${escapedPassword}')`
            const query = await controller.customQuery(str)
            if (query.length === 0) {
                return  res.status(401).json({ message: 'Credenciales inválidas.' })
            }
            const user = query[0]

            // If user has no deviceId yet, set it (use email or username columns as fallback)
            if (!user.deviceId || user.deviceId === ''){
                // Actualizamos solo por `username` (no existe columna `email` en la tabla)
                const updateStr = `UPDATE users SET deviceId='${escapedDeviceId}' WHERE username='${escapedEmail}'`
                try{
                    await controller.customQuery(updateStr)
                    user.deviceId = device
                }catch(e){
                    console.error('error updating deviceId', e)
                }
            }

            if (user.deviceId !== device && user.role !== 1){
                return res.status(403).json({ message: 'Dispositivo no autorizado.' })
            }

            // Build token payload (use id if available, otherwise email)
            const userId = user.id || user.ID || user.userId || user.email || user.username
            const payload = { sub: userId, email: user.email || user.username }
            const token = jwt.sign(payload, config.jwtSecret, { expiresIn: '7d' })

            res.status(200).json({ token })
        } catch (error) {
            console.log('error en login... ', error)
            res.status(500).json({ message: 'Puede soicitar sus credenciales con el encargado.' })
        }
    },
}
