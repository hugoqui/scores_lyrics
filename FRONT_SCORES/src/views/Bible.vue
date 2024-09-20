<template>
  <div class="container-fluid mt-5 mb-5 rounded shadow-lg" style="max-width: 1200px; background-color: rgba(0,0,0,0.1);">  
      
    <div class="row">
      <div class="col">
        <button id="clear-btn" @click="cleanScreen()">Limpiar</button>
      </div>
    </div>
     
    <div class="row my-4">
      <div class="col-12">
        <h1 class="gold text-center mb-4 font-weight-bold">Biblia - RV60</h1>
      </div>
      <!-- BUSCAR VERSO -->
      <div class="col-md-6 p-3">        
        <div class="shadow-lg p-4">
          <strong class="gold mb-4">Seleccionar Verso</strong> <br>
  
          <input class="input-search mt-2" type="text" v-model="searchedBook" placeholder="Libro" list="books" autocomplete="on" @change="findBook(searchedBook)">
          <datalist id="books">
            <option v-for="book in books" :value="book.idBook" :key="book.idBook">{{book.likeName}}</option>
          </datalist>
          
          <input class="input-search" type="text" v-model="searchedChapterNumber" placeholder="Cap" 
                 list="chapters" autocomplete="on" @change="getVerses(searchedChapterNumber)"
                 style="width: 80px;">
          <datalist id="chapters">
            <option v-for="chapter in chapters" :key="chapter.chapter">{{chapter.chapter}}</option>
          </datalist>
          
          <input class="input-search" type="text" v-model="searchedVerseNumber" placeholder="Verso" 
                 list="verses" autocomplete="on" @change="showVerse(searchedVerseNumber)"
                 style="width: 80px;">
          <datalist id="verses">
            <option v-for="verse in verses" :key="verse.verse">{{verse.verse}}</option>
          </datalist>
          
          
          <section class="text-left gold p-2 pt-3" >
            <p style="font-size:16px">{{previousScripture.text}}</p>
            <b class="text-white">{{previousScripture.reference}} </b>          
          </section>        
          
          <section class="text-left gold p-2 pt-3" style="background-color:rgba(0,0,0,0.2)" >
            <p style="font-size:16px">{{scripture.text}}</p>
            <b class="text-white">{{scripture.reference}} </b>          
          </section>
        
          <section class="text-left gold p-2 pt-3" >
            <p style="font-size:16px">{{followingScripture.text}}</p>
            <b class="text-white">{{followingScripture.reference}} </b>          
          </section>        
        </div>
      </div>

      <div class="col-md-6 p-3">   
        <div class="shadow-lg p-4">
          <form @submit.prevent="searchVerse()" >
            <div class="input-group">
              <input v-model="searchedText" type="text" class="form-control" placeholder="buscar... " >
              <div class="input-group-append">
                <button type="submit" class="btn bg-darker gold">buscar</button>
              </div>
            </div>
          </form> 
          
          <section v-if="searchedVerses.length > 0" style="max-height: 360px; overflow-y: scroll;" class="mt-2">
            <div @click="selectVerse(verse)" v-for="verse in searchedVerses" :key="verse.reference" class="p-2 gold my-1" style="cursor:pointer; background-color: rgba(0,0,0,0.1);">
              {{verse.text}} <b class="text-secondary">{{verse.reference}}</b>
            </div>          
          </section>
        </div>
      </div>
    </div>

  </div>
</template>

<script>

import bible from '../../../BACK_SCORES/src/controllers/bible';

export default {

  data: ()=>({
    books:[],
    chapters:[],
    verses:[],
    searchedText: "", 
    searchedVerses: [],
    scripture:"",

    selectedBook:1,
    selectedChapter:1,
    selectedVerse:1,
    url: "",

    searchedBook:"",
    searchedChapterNumber:"",
    searchedVerseNumber:"",

    followingScripture:{},
    previousScripture:{},

    completeBible: [],
  }),
  async mounted(){
    document.addEventListener("keydown", this.nextVerse)
    this.url = this.$store.state.url
    await this.getBooks()
    await this.getChapters(1)
    this.getCompleteBible()
  },
  methods:{
    async getBooks(){
      const req = await fetch(this.url + "books")
      let books = await req.json()
      this.books = books.map(b=>{
        let res = {idBook : b.idBook, name: b.name, reference: b.reference}
        let likeName = b.name.toLowerCase()
        likeName = likeName.replace("á", "a")
        likeName = likeName.replace("é", "e")
        likeName = likeName.replace("í", "i")
        likeName = likeName.replace("ó", "o")
        likeName = likeName.replace("ú", "u")
        res.likeName = likeName 
        return res
      })
      console.log(this.books[0])
    },

    async getChapters(bookId){
      this.selectedBook = bookId
      const url = this.url + "chapters/" + bookId      
      const req = await fetch(url)
      this.chapters = await req.json()

      //getverses
      this.selectedChapter = 1
      this.getVerses(1)
    },
    
    async getVerses(chapter){
      this.selectedChapter = chapter
      const url = this.url + "verses/" + this.selectedBook + "/" + chapter      
      const req = await fetch(url)
      this.verses = await req.json()

    },

    async showVerse(verse){
      let scripture
      
      if (verse < this.verses.length) {
        scripture = this.completeBible.find(v=> v.idBook == this.selectedBook && v.chapter == this.selectedChapter &&  v.verse == Number(verse)+1)      
        scripture.reference = `${this.searchedBook} ${this.selectedChapter}:${Number(verse)+1}`
        this.followingScripture = {...scripture}        
      }
      
      if (verse > 1) {
        scripture = this.completeBible.find(v=> v.idBook == this.selectedBook && v.chapter == this.selectedChapter &&  v.verse == Number(verse)-1)      
        scripture.reference = `${this.searchedBook} ${this.selectedChapter}:${Number(verse)-1}`
        this.previousScripture = {...scripture}        
      }
                     
      this.selectedVerse = Number(verse)
      scripture = this.completeBible.find(v=> v.idBook == this.selectedBook && v.chapter == this.selectedChapter &&  v.verse == verse)      
      scripture.reference = `${this.searchedBook} ${this.selectedChapter}:${verse}`
      this.scripture = {...scripture}

      this.searchedVerses = []
      this.$socket.emit("text_change", this.scripture)
    },
    

    selectVerse(verse){
      this.selectedBook = verse.idBook
      this.selectedChapter = verse.chapter
      this.showVerse(verse.verse)
    },

    async searchVerse(){
      const url = this.url + "search/"+ this.searchedText
      const req = await fetch(url)
      this.searchedVerses = await req.json()
    },

    nextVerse(event){
      if (event.keyCode ===40) {
        console.log("next...")
        this.showVerse(this.selectedVerse+1)
      } else if (event.keyCode ===38) {
        console.log("prev...")
        this.showVerse(this.selectedVerse-1)        
      }
    },

    async cleanScreen(){
        this.selectedVerse = 0
        let data = {}
        data.text = ""
        data.reference = ""
        data.title = ""
        this.$socket.emit("text_change", data)
    },

    async getCompleteBible(){
      console.log("descargando biblia completa...")
      const req = await fetch(this.url + "completeBible")
      this.completeBible = await req.json()
      console.log("biblia completa descargada")

      console.log(this.completeBible[0])
    },

    //autocomplete
    findBook(id){
      const book = this.books.find(b=> b.idBook == id)
      if (book) {
        this.getChapters(id)
        this.searchedBook = book.name
        return
      }

      this.searchedBook = ""
    }

  }
}
</script>


<style>
.input-search{
  border:none;
  padding: 8px;
  margin-right: 8px;
  border-radius: 4px;
}
</style>