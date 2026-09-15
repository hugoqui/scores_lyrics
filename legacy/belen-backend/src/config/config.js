
let config = {
    host: 'iglesiacristianabelen.com',
    user: 'belen',
    password: '4mp2p4ZyP8sbiPjn',
    database: 'belen',
    connectionLimit: 0
}


// let config = {
//     host: 'localhost',
//     user: 'belen',
//     password: '4mp2p4ZyP8sbiPjn',
//     database: 'belen',
//     connectionLimit: 0
// }

// JWT secret: read from env in production, fallback for local development
config.jwtSecret = process.env.JWT_SECRET || 'replace-this-secret-in-production'

module.exports = config