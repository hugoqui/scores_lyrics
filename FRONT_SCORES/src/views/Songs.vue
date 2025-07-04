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
                <button type="button" class="btn btn-secondary" @click="modalVisible=false;" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary" @click="modalVisible=false;createSong()" data-dismiss="modal">Guardar</button>
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
                <button type="button" class="btn btn-secondary" @click="modalVisible=false;" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary" @click="modalVisible=false;saveChanges()" data-dismiss="modal">Guardar</button>
            </div>
            </div>
        </div>
    </div>

    <div class="row mt-2">

        <div class="col-4 mb-4" style="max-height:96vh; overflow:auto; ">
            <!-- SEARCH - ADD NEW -->
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
                    <button @clikc="modalVisible=true" class="btn btn-outline-warning" data-toggle="modal" data-target="#addNewModal">+ Agregar Nuevo</button>
                </div>
            </div>

            <!-- First List "all songs" -->
            <h1 data-toggle="modal" data-target="#modifyModal" id="triggerModal" ref="triggerModal"></h1>
            <div class="row mt-3">
                <div class="col-lg-4 col-md-6 col-sm-12" v-for="(song, i) in filteredSongs" style="padding: 8px;">
                    <SongItem @selected="addSong(song)" :type="'gold'"
                              @edit="showSongDetails(song.id)" :showEdit="true"
                              :key="song.id" :song="song"/>

                </div>
            </div>


            <!-- <div v-for="(song) in filteredSongs" :key="song.id"
                class="mt-3 mb-2 p-2 bg-gold white zoom" style="cursor:pointer">
                <div class="row">
                    <div class="col" >
                        <img src="@/assets/pen.png" alt="belen" class="mt-1" style="cursor:pointer;" height="15"
                            @click="showSongDetails(song.id)" data-toggle="modal" data-target="#modifyModal">
                    </div>
                    <div class="col-8" @click="addSong(song)">
                        <h5 class="text-uppercase" style="text-shadow:0px 0px 8px #000">{{ song.title }}</h5>
                    </div>
                    <div class="col">
                        <img src="@/assets/arrow.png" alt="belen" class="mt-3 img-fluid" style="cursor:pointer;"
                            @click="addSong(song)"> <br>
                    </div>
                </div>
            </div> -->

        </div>

        <div class="col-4" style="max-height:96vh; overflow:auto; ">
            <div class="col-12">
                <h6 class="white text-center mb-4">LISTADO</h6>
            </div>

            <div class="row mt-3">
                <div class="col-lg-4 col-md-6 col-sm-12" v-for="(song, i) in worshipList"  style="position: relative;">
                    <SongItem @selected="inputSong=song.lyrics; songTitle=song.title"
                              @remove="removeFromList(i)" @edit="showSongDetails(song.id)"
                              :showEdit="true" :showDelete="true"
                              :type="'dark'" :key="song.id" :song="song"/>
                </div>

                <button id="clear-btn" @click="cleanScreen()">Limpiar</button>
            </div>
        </div>

        <div class="col-4" style="max-height:96vh; overflow:auto; ">
             <div class="col-12">
                <h6 class="white text-center mb-4">TRANSMISIÓN</h6>
            </div>

            <div class="border p-3 m-3 rounded border border-warning white zoom paragraph" v-for="(verse, i) in verses" :key="verse.id"
                :class="selectedVerse == i+1 ? 'active' : ''"  style="cursor:pointer"
                @click="showVerse(verse,i)">
                <strong>ESTROFA #{{i+1}}</strong> <br>
                {{verse}}
            </div>
        </div>
    </div>
  </div>
</template>

<script>

import SongItem from "../components/SongItem.vue";

export default {
    components: { SongItem},
    data:()=>({
        inputSong:"",
        allSongs:[],
        filteredSongs:[],
        searchedText:"",
        worshipList:[],

        verses:[],
        selectedVerse:0,
        url: null,

        newSong:{},
        selectedSong:{},

        songTitle: "",
        modalVisible:false

    }),
    watch:{
        inputSong: function(val){
            try {
                this.verses = val.split("*")
            } catch (error) {
                console.error(error)
            }
        },
    },
    mounted(){
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
            console.log("enviando a socket ... ", data )
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
                this.$refs["triggerModal"].click()
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
            const url = this.url + "songList/" + id
            const opts = {method:"DELETE", headers: {'Content-Type': 'application/json'}}
            fetch(url, opts)

            this.worshipList.splice(i,1)
        },

        nextItem(event){
           if (this.modalVisible) return

           const i = this.selectedVerse
           if (event.keyCode ===40) {
                console.log("next...")
                this.showVerse(this.verses[i], i )
            } else if (event.keyCode ===38) {
                console.log("prev...")
                this.showVerse(this.verses[i-2], i-2 )
            }
            else if (event.keyCode === 27){
                this.cleanScreen()
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

        },

        async cleanScreen(){
            console.log("clearing screen...")
            this.selectedVerse = 0
            let data = {}
            data.text = ""
            data.reference = ""
            data.title = ""
            this.$socket.emit("song_change", data)
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

    .paragraph {
        -webkit-user-select: none; /* Safari */
        -ms-user-select: none; /* IE 10 and IE 11 */
        user-select: none;
    }
</style>