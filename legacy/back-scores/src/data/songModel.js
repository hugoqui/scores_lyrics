class SongModel{
    constructor(){

    }

    static songList =[]

    static removeFromList(id){
        console.log("from class... ", id)
        const i = this.songList.findIndex(item => item.id == id)
        console.log("index... ", i)
        console.log("song..", this.songList[i].title)
        this.songList.splice(i,1)
    }
}

module.exports = SongModel