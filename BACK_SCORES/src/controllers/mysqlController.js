module.exports = {
    getAll: async function(tableName, selector = '*', condition = 'WHERE 1=1') {
        try {
            let str = `SELECT ${selector} FROM ${tableName} ${condition};`
            console.log(str)
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }
                    resolve(rows)
                })
            })
        } catch (err) {
            console.log('error en getList ... ', err)
            throw err
        }
    },

    findById: async function(tableName, id, idField='id') {
        try {
            let str = `SELECT * FROM ${tableName} WHERE ${idField}='${id}'`
            console.log(str)
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }                    
                    resolve(rows[0])
                })
            })
        } catch (err) {
            console.log('error en findById ... ', err)
            throw err
        }
    },

    create: async function(tableName, data) {
        let columNames = Object.keys(data)

        let values = '( '
        for (i = 0; i < columNames.length; i++) {
            values += '`' + columNames[i] + '`'

            if (i < columNames.length - 1) { values += ', ' }
        }
        values += ' ) VALUES ('

        for (i = 0; i < columNames.length; i++) {
            let columName = columNames[i]
            let val = data[columName]
            values += `'${val}'`
            if (i < columNames.length - 1) { values += ', ' }
        }
        values += ' );'

        let str = `INSERT INTO ${tableName} ${values}`
        console.log('query del insert...', str)
        try {
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }
                    //console.log(rows)
                    resolve(rows)
                })
            })
        } catch (err) {
            console.log('error en create ... ', err)
            throw err
        }
    },


    update: async function(tableName, data, id, idField='id' ) {
        let columNames = Object.keys(data)
        let values = ''

        for (i = 0; i < columNames.length; i++) {
            let columName = columNames[i]
            let val = data[columName]
            
            if (val == null){
                values += '`' + columName + '` = ' + `${val}`
            } else {                
                values += '`' + columName + '` = ' + `'${val}'`
            }



            if (i < columNames.length - 1) { values += ', ' }
        }
        values += ` WHERE ${idField}='${id}';`

        let str = `UPDATE ${tableName} SET ${values}`
        console.log(str)
        try {
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }
                    console.log(rows)
                    resolve(rows)
                })
            })
        } catch (err) {
            console.log('error en update ... ', err)
            throw err
        }
    },

    delete: async function(tableName, id) {
        try {
            let str = `DELETE  FROM ${tableName} WHERE id=${id}`
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }
                    console.log(rows)
                    resolve(rows)
                })
            })
        } catch (err) {
            console.log('error en delete ... ', err)
            throw err
        }
    },

    customQuery: async function(str) {
        console.log('customQuery function.... ')
        try {
            return new Promise((resolve, reject) => {
                pool.query(str, (error, rows) => {
                    if (error) {
                        console.log(error)
                        reject(error)
                    }
                    //console.log(rows)
                    resolve(rows)
                })
            })
        } catch (err) {
            console.log('error en customQuery ... ', err)
            throw err
        }
    }

}