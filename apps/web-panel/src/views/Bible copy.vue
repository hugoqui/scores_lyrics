<template>
  <div class="container-fluid mt-2 mb-5">
      
    <div class="row">
      <div class="col">
        <button id="clear-btn" @click="cleanScreen()">Limpiar</button>
        <!-- <input type="text" v-model="searchedBook" placeholder="Libro" list="books" autocomplete="on">
        <datalist id="books">
          <option v-for="book in books" :value="book.idBook" :key="book.idBook">{{book.likeName}}</option>
        </datalist> -->
      </div>

      <form  @submit.prevent="searchVerse()" class="col-md-6">
        <div class="input-group">
          <input v-model="searchedText" type="text" class="form-control" placeholder="buscar... " >
          <div class="input-group-append">
            <button type="submit" class="btn bg-darker gold">buscar</button>
          </div>
        </div>
      </form>
    </div>

    <div class="row" v-if="searchedVerses.length > 0">
      <div class="col-md-4">
        <div @click="selectVerse(verse)" v-for="verse in searchedVerses" :key="verse.reference" class="border p-2 gold my-1" style="cursor:pointer">
          {{verse.text}}
          <i> {{verse.reference }} </i>
        </div>
      </div>
    </div>

    <div class="row mt-3">
      <!-- LIBROS -->
      <div class="col-4" style="height:72vh; overflow-y:auto">
        <div class="row">
          <div class="col-4" v-for="book in books" :key="book.id" 
                style="cursor:pointer;" @click="getChapters(book.idBook)">
              <div class="p-1 mt-2 text-center " style="height:5rem; display:flex;" 
                    :class="selectedBook == book.idBook ? 'bg-gold dark' : 'bg-darker white'">
                <div style="margin: auto;" class="h5"> {{book.reference}}</div> 
              </div>
          </div>
        </div>
      </div>
      
      <!-- CAPITULOS -->
      <div class="col">
        <div style="max-height:72vh; overflow-y:auto; border-left:1px solid #FFCD30; border-right:1px solid #FFCD30;" class="row">
          <div class="col-4" v-for="chapter in chapters" :key="chapter.id" >
            <div class="p-3  text-center h4  " style="cursor:pointer"
                :class="selectedChapter == chapter.chapter ? 'bg-gold dark' : 'bg-darker white'" 
                @click="getVerses(chapter.chapter)">
              {{chapter.chapter}}
            </div>
          </div>
        </div>
      </div>
      
      <div class="col">
        <div style="max-height:72vh; overflow-y:auto" class="row">
          <div class="col-4" v-for="verse in verses" :key="verse.id" >            
            <div class="p-3 text-center h4" style="cursor:pointer"
                :class="selectedVerse == verse.verse ? 'bg-gold dark' : 'bg-darker white'" 
                @click="showVerse(verse.verse)">
              {{verse.verse}}
            </div>
          </div>
        </div>
      </div>

    </div>
    <div class="row mt-2" style="height:10vh">
      <div class="col-4">
        <section class="text-center gold p-2 pt-3" >
          <p style="font-size:1.25rem">{{previousScripture.text}}</p>
          <span>{{previousScripture.reference}} </span>          
        </section>
      </div>
      <div class="col-4">
        <section class="text-center gold p-2 pt-3" style="background-color:rgba(0,0,0,0.2)" >
          <p style="font-size:1.25rem">{{scripture.text}}</p>
          <span>{{scripture.reference}} </span>          
        </section>
      </div>
      <div class="col-4">
        <section class="text-center gold p-2 pt-3" >
          <p style="font-size:1.25rem">{{followingScripture.text}}</p>
          <span>{{followingScripture.reference}} </span>          
        </section>
      </div>
    </div>

  </div>
</template>

<script>

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
  }),
  async mounted(){
    document.addEventListener("keydown", this.nextVerse)
    this.url = this.$store.state.url
    await this.getBooks()
    await this.getChapters(1)    
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
      
      let url = this.url + "verse/" + this.selectedBook + "/" + this.selectedChapter + "/" + (verse+1)           
      let req = await fetch(url)
      this.followingScripture = await req.json()
      
      url = this.url + "verse/" + this.selectedBook + "/" + this.selectedChapter + "/" + (verse-1)           
      req = await fetch(url)
      this.previousScripture = await req.json()
      
      this.selectedVerse = verse
      url = this.url + "verse/" + this.selectedBook + "/" + this.selectedChapter + "/" + verse  + "/true"         
      req = await fetch(url)
      this.scripture = await req.json()
      this.searchedVerses = []

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
        this.$socket.emit("song_change", data)
    }
  }
}
</script>
