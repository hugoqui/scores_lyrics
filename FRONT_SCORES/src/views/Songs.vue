<template>
  <div class="container-fluid">
        
    <!-- add new modal -->
    <div class="modal fade" id="addNewModal" tabindex="-1" >
        <div class="modal-dialog">
            <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="exampleModalLabel">Agregar Nuevo Canto</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <input type="text" class="form-control m-1" v-model="newSong.title" placeholder="Título">
                <input type="text" class="form-control m-1" v-model="newSong.chord" placeholder="Acorde Base (ej: C)">
                <textarea type="text" class="form-control m-1" v-model="newSong.lyrics" rows="10" placeholder="Separe las estrofas con *"></textarea>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary" @click="createSong()" data-dismiss="modal">Guardar</button>
            </div>
            </div>
        </div>
    </div>
    
    <!-- modify modal -->
    <div class="modal fade" id="modifyModal" tabindex="-1" >
        <div class="modal-dialog">
            <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="exampleModalLabel">Editar  Canto</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <input type="text" class="form-control m-1" v-model="selectedSong.title" placeholder="Título">
                <input type="text" class="form-control m-1" v-model="selectedSong.chord" placeholder="Acorde Base (ej: C)">
                <textarea type="text" class="form-control m-1" v-model="selectedSong.lyrics" rows="10" placeholder="Separe las estrofas con *"></textarea>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary" @click="saveChanges()" data-dismiss="modal">Guardar</button>
            </div>
            </div>
        </div>
    </div>

    <div class="row mt-2 mb-3">
        <div class="col-12">
            <h1 class="white text-center">Lyrics & Scores</h1>
        </div>
    </div>

    <div class="row">
        <div class="col-md-4" style="max-height:85vh; overflow:auto; ">
            <div class="row">
                <div class="col-12">
                    <h6 class="white text-center mb-4">TODOS LOS CANTOS</h6>                    
                </div>
                <div class="col-12">
                    <div class="input-group mb-3">
                        <div class="input-group-prepend">
                            <span class="input-group-text bg-white" >
                                <img src="@/assets/search.png" alt="">
                            </span>
                        </div>
                        <input v-model="searchedText" @keydown.enter="search()" type="text" class="form-control" placeholder="buscar canto..." >
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-6">
                    <button class="btn btn-outline-warning" data-toggle="modal" data-target="#addNewModal">+ Agregar Nuevo</button>                
                </div>
            </div>

            <!-- First List "all songs" -->

            <div v-for="(song) in filteredSongs" :key="song.id"                 
                class="mt-3 mb-2 p-2 bg-gold white zoom" style="cursor:pointer">
                <div class="row">
                    <div class="col">                        
                        <img src="@/assets/pen.png" alt="belen" class="mt-1" style="cursor:pointer;" height="15"
                            @click="showSongDetails(song.id)" data-toggle="modal" data-target="#modifyModal">                        
                        
                        <!-- <img src="@/assets/trash.png" alt="belen" class="mt-3" style="cursor:pointer;" height="15"
                            @click=""> -->
                    </div>
                    <div class="col-8" @click="addSong(song)">
                        <h5 class="text-uppercase" style="text-shadow:0px 0px 8px #000">{{ song.title }}</h5> 
                        <!-- <p style="white-space: nowrap; width: 100%; overflow: hidden; text-overflow: ellipsis;" 
                            v-if="song.lyrics && song.lyrics.indexOf('*')>-1">
                            {{song.lyrics.split('*')[0]}}
                        </p> -->
                    </div>
                    <div class="col">
                        <img src="@/assets/arrow.png" alt="belen" class="mt-3 img-fluid" style="cursor:pointer;"
                            @click="addSong(song)"> <br>                        
                    </div>
                </div>
            </div>

        </div>

        <div class="col-md-4" style="max-height:85vh; overflow:auto; ">
            <div class="col-12">
                <h6 class="white text-center mb-4">LISTADO</h6>                    
            </div>
            <div v-for="(song,i) in worshipList" :key="song.id"            
                class="mt-3 mb-2 p-2 bg-darker white animated zoom">
                <div class="row">
                    <div class="col">
                        <img src="@/assets/trash.png" alt="belen" class="mt-3" style="cursor:pointer;" height="15"
                            @click="removeFromList(i)">
                    </div>
                    <div class="col-8" @click="inputSong=song.lyrics; songTitle=song.title"  style="cursor:pointer"> 
                        <h5 class="text-uppercase">{{ song.title }}</h5> 
                        <p style="white-space: nowrap; width: 100%; overflow: hidden; text-overflow: ellipsis;" 
                            v-if="song.lyrics && song.lyrics.indexOf('*')>-1">
                            {{song.lyrics.split('*')[0]}}
                        </p>
                    </div>
                    <div class="col" style="cursor:pointer">
                        <img src="@/assets/arrow.png" alt="belen" class="mt-3 img-fluid" style="cursor:pointer;"
                        @click="inputSong=song.lyrics; songTitle=song.title">
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-4" style="max-height:85vh; overflow:auto; ">
             <div class="col-12">
                <h6 class="white text-center mb-4">TRANSMISIÓN</h6>                    
            </div>

            <div>
                <div class="border p-3 m-3 rounded border border-warning white zoom" v-for="(verse, i) in verses" :key="verse.id"
                    :class="selectedVerse == i+1 ? 'active' : ''"  style="cursor:pointer"
                    @click="showVerse(verse,i)">
                    <strong>ESTROFA #{{i+1}}</strong> <br>
                    {{verse}}
                </div>
            </div>
        </div>
    </div>
  </div>
</template>

<script>

import SongsData from "@/assets/songs.json" 

export default {
    data:()=>({
        inputSong:"",
        allSongs:[],
        filteredSongs:[],
        searchedText:"",
        worshipList:[],

        selectedSongStep1:0,
        selectedSongStep2:0,       

        verses:[],
        selectedVerse:0,
        url: null,

        newSong:{},
        selectedSong:{},

        songTitle: "",

    }),
    watch:{
        inputSong: function(val){
            try {
                this.verses = val.split("*")                
            } catch (error) {
                console.error(error)
            }
        },

        selectedSongStep1: function(val){
            console.log(val)
        }
    },
    mounted(){
        console.log("mounted songs...")
        document.addEventListener("keydown", this.nextItem)
        this.url = this.$store.state.url
        console.log("el host... ", this.url)
        this.getData()
        this.getList()        
    },
    methods:{
        async getData(){
            const req = await fetch(this.url + "songs")
            this.allSongs = await req.json()
            
            // this.allSongs = SongsData // for dev
            this.filteredSongs = this.allSongs
        },

        async getList(){
            const req = await fetch(this.url + "songList")
            this.worshipList = await req.json()            
        },
        
        showVerse(verse, i){
            this.selectedVerse = i+1
            let data = {}
            data.text = verse
            data.reference = ""
            data.title = this.songTitle
            this.$socket.emit("song_change", data)
        },

        async createSong(){
            try {
                const url = this.url + "song"
                const opts = {method:"post", headers: {'Content-Type': 'application/json'}, body: JSON.stringify(this.newSong)}
                const req = await fetch(url, opts)
                this.newSong = {}
                this.getData()
            } catch (error) {
                alert(error)
            }
        },

        async showSongDetails(id){
            try {
                const url = this.url + "song/" + id                 
                const req = await fetch(url,)
                this.selectedSong = await req.json()                
            } catch (error) {
                alert(error)
            }
        },

        async saveChanges(){
            try {
                const url = this.url + "song/" + this.selectedSong.id
                const opts = {method:"put", headers: {'Content-Type': 'application/json'}, body: JSON.stringify(this.selectedSong)}
                await fetch(url, opts)
                
                const foundIndex = this.worshipList.findIndex(s=> s.id == this.selectedSong.id)
                if (foundIndex >-1) {
                    this.worshipList[foundIndex] = {...this.selectedSong}
                }

                this.getData()
            } catch (error) {
                alert(error)
            }
        },

        search(){
            if (this.searchedText == "") {
                this.filteredSongs = this.allSongs
            }else {
                console.log(console.log("buscando... ", this.searchedText))
                this.filteredSongs = this.allSongs.filter(s=> s.title.toLowerCase().trim().indexOf(this.searchedText.toLowerCase().trim()) > -1) 
            }
        },

        removeFromList(i){                        
            const id = this.worshipList[i].id
            // alert(id + " - " + this.worshipList[i].title)

            const url = this.url + "songList/" + id
            const opts = {method:"DELETE", headers: {'Content-Type': 'application/json'}}
            fetch(url, opts)
            
            this.worshipList.splice(i,1)
        },

        nextItem(event){
            const i = this.selectedVerse
           if (event.keyCode ===40) {
                console.log("next...")
                this.showVerse(this.verses[i], i )
            } else if (event.keyCode ===38) {
                console.log("prev...")                
                this.showVerse(this.verses[i-2], i-2 )
            }
        },

        async addSong(song){
            const found = this.worshipList.findIndex(s=> s.id == song.id)
            if (found > -1){
                this.worshipList[found] = song
                return
            } 

            this.worshipList.push(song)

            const url = this.url + "songList"
            const opts = {method:"POST", headers: {'Content-Type': 'application/json'}, body: JSON.stringify(song)}
            await fetch(url, opts)
                
        }
    }
}
    


</script>

<style lang="scss" scoped>
    
    div .active{
        background: #FFCD30;
        color: #343740;
        font-weight: bold;
    }

    .animated{
        position: relative;
        top:0;
        animation-name: example;
        animation-duration: 300ms;
    }

    @keyframes example {
        0%   {top:100px;}        
        100% {top:0px;}
    }
</style>