<template>
  <div class="container-fluid my-3 mb-5 rounded shadow-lg no-selectable"
       style="max-width: 1400px; background-color: rgba(0,0,0,0.1);">
    
    <div class="row my-4">
      <!-- BUSCAR POR CONTENIDO -->
      <div class="col-md-4 ">
        <h1 class="gold text-center mt-3 mb-4 font-weight-bold">Biblia - RV60</h1>
        <div class="shadow-lg p-4">
          <form @submit.prevent="searchVerse()">
            <div class="input-group">
              <input v-model="searchedText" type="text" class="form-control" placeholder="buscar... ">
              <div class="input-group-append">
                <button type="submit" class="btn bg-darker gold">buscar</button>
              </div>
            </div>
          </form>

          <section v-if="searchedVerses.length > 0" style="max-height: 65vh; overflow-y: scroll;" class="mt-2">
            <div @click="showSearchedVerse(verse)" v-for="verse in searchedVerses" :key="verse.reference"
              class="p-2 gold my-1" style="cursor:pointer; background-color: rgba(0,0,0,0.1);">
              {{ verse.text }} <b class="text-secondary">{{ verse.reference }}</b>
            </div>
          </section>
        </div>
      </div>

      <!-- ESCRIBIR PASAJE -->
      <div class="col-md-4 ">
        <div class="shadow-lg p-4 mt-5">
          <button class="btn btn-dark float-right px-4 " style="border-radius: 3rem; background-color: rgba(0,0,0,0.4);" @click="cleanScreen()">Limpiar</button>
          <br>
          <strong class="gold mb-4">Seleccionar Verso</strong> <br>

          <div style="display: flex;" class="mt-2">
            <input class="input-search " type="text" v-model="selectedBook" placeholder="Libro" list="books"
              autocomplete="on" @input="onInputChange"  @focus="selectAllText" @change="findBook(selectedBook)">
            <datalist id="books">
              <option v-for="book in books" :value="book.idBook" :key="book.idBook">{{ book.likeName }}</option>
            </datalist>
  
            <input ref="chapterBox" class="input-search" type="number" v-model.lazy="selectedChapter" placeholder="Cap" 
                @focus="selectAllText" @change="getChapterVerses(selectedChapter)" style="width: 80px;">
  
            <input ref="verseBox" class="input-search" type="number" v-model="preSelectedVerse" placeholder="Verso" 
                @focus="selectAllText" @keyup.enter="showVerse(preSelectedVerse)" style="width: 80px;">          
          </div>


          <div class="mt-3 text-center" v-if="scripture">
            <button class="shadow btn bg-dark gold" @click="changeVerse('up')">< Anterior</button>
            <button class="shadow btn bg-dark gold ml-3" @click="changeVerse('down')">Siguiente ></button>
          </div>

          <section class="text-left gold p-2 pt-3 mt-4 zoom" style="background-color:rgba(0,0,0,0.2)" @click="showVerse(selectedVerse)">
            <p style="font-size:16px">{{scripture.text}}</p>
            <b class="text-white">{{scripture.reference}} </b>          
          </section>

        </div>

      </div>

      <!-- LISTA DE VERSICULOS -->
      <div class="col-md-4 ">
        <div ref="verseContainer"
             class="shadow-lg m-2 p-4 gold" style="height: 90vh; overflow-y: auto;">

          <section v-for="verse in chapterVerses" class="my-2 shadow rounded p-2 zoom "
                  :ref="'verse_' + verse.verse" @click="showVerse(verse.verse)"
                  style="background-color:rgba(250,250,250,0.05)"
                  :class="selectedVerse== verse.verse ? 'bg-warning text-dark' : ''">
            {{ verse.text }}
            <label class="text-white" :class="selectedVerse== verse.verse ? 'font-weight-bold text-dark' : ''">
              {{ verse.name }} {{ verse.chapter }}:{{ verse.verse }}
            </label>
            
          </section>
        </div>

      </div>

    </div>

  </div>
</template>

<script>

export default {

  data: () => ({
    books: [],
    chapters: [],
    verses: [],
    searchedText: "",
    searchedVerses: [],
    scripture: "",
        
    url: "",

    selectedBook: null,
    selectedId: null,
    selectedChapter: null,
    preSelectedVerse: null, 
    selectedVerse: null,

    followingScripture: {},
    previousScripture: {},

    completeBible: [],
    chapterVerses: [],

  }),
  async mounted() {    
    document.body.style.overflowY = 'hidden'
    this.url = this.$store.state.url
    await this.getBooks()    
    this.getCompleteBible()
  },

  beforeDestroy() {
    document.body.style.overflowY = 'auto';
  },

  watch: {
    selectedBook: function (val) {
      if (val == "") {
        this.chapterVerses = []
        this.selectedChapter = null
        this.selectedVerse = null
        this.preSelectedVerse = null
        this.scripture = {}
        return
      }      
      this.selectedChapter = ""      
    },
  },

  methods: {
    async getBooks() {
      const req = await fetch(this.url + "books")
      let books = await req.json()
      this.books = books.map(b => {
        let res = { idBook: b.idBook, name: b.name, reference: b.reference }
        let likeName = b.name.toLowerCase()
        likeName = likeName.replace("á", "a")
        likeName = likeName.replace("é", "e")
        likeName = likeName.replace("í", "i")
        likeName = likeName.replace("ó", "o")
        likeName = likeName.replace("ú", "u")
        res.likeName = likeName
        return res
      })
            
    },

    async getChapters(bookId) {
      this.selectedBook = bookId
      const url = this.url + "chapters/" + bookId
      const req = await fetch(url)
      this.chapters = await req.json()      
    },

    async getChapterVerses(chapter) {
      if (this.selectedBook == "") {
        this.selectedChapter = ""
        this.selectedVerse = ""
        this.preSelectedVerse = ""
        this.scripture = {}
        return
      }      

      this.chapterVerses = this.completeBible.filter(b => b.idBook == this.selectedBookId && b.chapter == chapter)
      this.$refs["verseBox"].focus()
    },

    async showVerse(verse) {
      this.selectedVerse = verse
      let scripture = this.completeBible
        .find(v => v.idBook == this.selectedBookId 
                  && v.chapter == this.selectedChapter 
                  && v.verse == verse)

      scripture.reference = `${this.selectedBook} ${this.selectedChapter}:${verse}`
      this.scripture = { ...scripture }

      this.searchedVerses = []
      this.$store.dispatch("showVerse", this.scripture)
      // this.$socket.emit("text_change", this.scripture)

      const verseElement = this.$refs[`verse_${verse}`];
     
      if (verseElement && verseElement.length > 0) {
        verseElement[0].scrollIntoView({ behavior: 'smooth', block: 'start' });
      } else if (verseElement) {
        verseElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    },


    selectVerse(verse) {
      this.selectedBookId = verse.idBook      
      setTimeout(() => {        
        this.selectedChapter = verse.chapter     
        this.preSelectedVerse = verse.verse                 
        this.showVerse(verse.verse)
      }, 300);
    },

    async searchVerse() {
      const url = this.url + "search/" + this.searchedText
      const req = await fetch(url)
      this.searchedVerses = await req.json()
    },

    showSearchedVerse(verse){     
      const {name} = this.books.find(b=> b.idBook == verse.idBook)
      this.selectedBook = name      
      
      this.selectVerse(verse)
      this.getChapterVerses(verse.chapter)
    },

    changeVerse(event) {
      if (event === "down") {        
        this.showVerse(Number(this.selectedVerse) + 1)
      } else if (event === "up") {        
        this.showVerse(Number(this.selectedVerse) - 1)
      }
    },

    async cleanScreen() {
      let data = {}
      data.text = ""
      data.reference = ""
      data.title = ""
      this.$socket.emit("text_change", data)
    },

    async getCompleteBible() {
      const req = await fetch(this.url + "completeBible")
      this.completeBible = await req.json()
    },

    //autocomplete
    findBook(id) {
      this.selectedBookId = id
      this.selectedVerse =null
      this.selectedChapter =null

      const book = this.books.find(b => b.idBook == id)
      if (book) {
        this.getChapters(id)
        this.selectedBook = book.name
        setTimeout(() => {
          this.$refs["chapterBox"].focus()          
        }, 300);
        
        return
      }

      this.selectedBook = ""
    },

    onInputChange() {      
      this.selectedBookId = null;
    },

    selectAllText(event) {
      event.target.select(); // Selecciona todo el texto en el input
    },

  }
}
</script>


<style>

.input-search {
  border: none;
  padding: 8px;
  margin-right: 8px;
  border-radius: 4px;
}
</style>