module.exports = {
    login: async (req, res) => {
        try {
            const users = [
                'alfredo.castellanos',
		'anaester.castellanos',
                'aline.castellanos',
                'hannah.castellanos',
                'elizabeth.castellanos',
                'camila.castellanos',
                'hugo.quinonez',
                'alexis.monterroso',
                'timoteo.castellanos',
                'brenda.lopez',
                'dulce.hernandez',
                'elizabet.mendia',
                'anaester.castellanos',
                'jimena.lopez',
                'sara.sabio',
                'lidia.sabio',
                'samuel.castellanos',
                'dara.guarcas',
                'luis.mendia',
                'mario.tucubal',
                'nahum.chanchavac',
                'nahomy.archila',
                'rut.archila',
                'obed.zapata',
                'josue.zapata',
                'analucia.zapata',
                'eliud.turcios',
                'alison.lopez',
                'david.lopez',
                'priscila.castellanos',
                'andrea.tucubal',
                'belen.tucubal',
                'yuli.tucubal',
                'rubi.tucubal',
                'paty.turcios',
                'emerson.tucubal',
                'debora.chanchavac',
                'dulce.guarcas',
                'jael.chanchavac',
                'levi.chanchavac',
            ]
            
            if (!users.includes(req.body.email)){ throw 'acceso dedegado' }
            
            res.status(200).json({token: '321ab59'})
        } catch (error) {
            console.log('error en login... ', error)
            res.status(500).json({message: 'Puede soicitar sus credenciales con el encargado.'})
        }
    },
}
