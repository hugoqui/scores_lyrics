<template>
  <div class="container-fluid my-3 mb-5 rounded shadow-lg"
       style="max-width: 1400px; background-color: rgba(0,0,0,0.1);">
    <button id="clear-btn" @click="cleanScreen()">Limpiar</button>

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
          <strong class="gold mb-4">Seleccionar Verso</strong> <br>

          <input class="input-search mt-2" type="text" v-model="searchedBook" placeholder="Libro" list="books"
            autocomplete="on" @change="findBook(searchedBook)">
          <datalist id="books">
            <option v-for="book in books" :value="book.idBook" :key="book.idBook">{{ book.likeName }}</option>
          </datalist>

          <input ref="chapterBox" class="input-search" type="text" v-model="searchedChapterNumber" placeholder="Cap" list="chapters"
            autocomplete="on" @change="getVerses(searchedChapterNumber)" style="width: 80px;">
          <datalist id="chapters">
            <option v-for="chapter in chapters" :key="chapter.chapter">{{ chapter.chapter }}</option>
          </datalist>

          <input ref="verseBox" class="input-search" type="text" v-model="searchedVerseNumber" placeholder="Verso" list="verses"
            autocomplete="on" @change="showVerse(searchedVerseNumber)" style="width: 80px;">
          <datalist id="verses">
            <option v-for="verse in verses" :key="verse.verse">{{ verse.verse }}</option>
          </datalist> 

          <div class="mt-3 text-center" v-if="scripture">
            <button class="shadow btn bg-dark gold" @click="changeVerse('up')">< Anterior</button>
            <button class="shadow btn bg-dark gold ml-3" @click="changeVerse('down')">Siguiente ></button>
          </div>

          <section class="text-left gold p-2 pt-3 mt-4" style="background-color:rgba(0,0,0,0.2)" @click="showVerse(Number(selectedVerse))">
            <p style="font-size:16px">{{scripture.text}}</p>
            <b class="text-white">{{scripture.reference}} </b>          
          </section>


        </div>

      </div>

      <!-- LISTA DE VERSICULOS -->
      <div class="col-md-4 ">
        <div ref="verseContainer"
             class="shadow-lg m-2 p-4 gold" style="height: 90vh; overflow-y: auto;">

          <section v-for="verse in chapterVerses" class="my-1 shadow rounded py-2"
                  :ref="'verse_' + verse.verse" 
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

    selectedBook: 1,
    selectedChapter: 1,
    selectedVerse: null,
    url: "",

    searchedBook: "",
    searchedChapterNumber: "",
    searchedVerseNumber: "",

    followingScripture: {},
    previousScripture: {},

    completeBible: [],
    chapterVerses: [],

  }),
  async mounted() {    
    document.body.style.overflowY = 'hidden'
    this.url = this.$store.state.url
    await this.getBooks()
    await this.getChapters(1)
    this.getCompleteBible()
  },

  beforeDestroy() {
    document.body.style.overflowY = 'auto';
  },

  watch: {
    searchedBook: function (val) {
      if (val == "") {
        this.chapterVerses = []
        this.selectedVerse = null
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
      this.selectedChapter = 1      
    },

    async getVerses(chapter) {
      if (this.selectedBook == "") {
        this.selectedChapter = ""
        return
      }      
      this.chapterVerses = this.completeBible.filter(b => b.idBook == this.selectedBook && b.chapter == chapter)
      this.$refs["verseBox"].focus()
    },

    async showVerse(verse) {
      this.selectedVerse = verse
      let scripture = this.completeBible.find(v => v.idBook == this.selectedBook && v.chapter == this.searchedChapterNumber && v.verse == verse)
      scripture.reference = `${this.searchedBook} ${this.searchedChapterNumber}:${verse}`
      this.scripture = { ...scripture }

      this.searchedVerses = []
      this.$socket.emit("text_change", this.scripture)

      const verseElement = this.$refs[`verse_${verse}`];
     
      if (verseElement && verseElement.length > 0) {
        verseElement[0].scrollIntoView({ behavior: 'smooth', block: 'start' });
      } else if (verseElement) {
        verseElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    },


    selectVerse(verse) {
      this.selectedBook = verse.idBook      
      this.selectedChapter = verse.chapter                  
      this.showVerse(verse.verse)
    },

    async searchVerse() {
      const url = this.url + "search/" + this.searchedText
      const req = await fetch(url)
      this.searchedVerses = await req.json()
    },

    changeVerse(event) {
      if (event === "down") {        
        this.showVerse(Number(this.selectedVerse) + 1)
      } else if (event === "up") {        
        this.showVerse(Number(this.selectedVerse) - 1)
      }
    },

    async cleanScreen() {
      this.selectedVerse = 0

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
      this.searchedVerseNumber =null
      this.searchedChapterNumber =null

      const book = this.books.find(b => b.idBook == id)
      if (book) {
        this.getChapters(id)
        this.searchedBook = book.name
        this.$refs["chapterBox"].focus()
        return
      }

      this.searchedBook = ""
    },

    showSearchedVerse(verse){
      console.log(verse)
      this.searchedChapterNumber = verse.chapter
      this.searchedVerseNumber = verse.verse      
      const {name} = this.books.find(b=> b.idBook == verse.idBook)
      this.searchedBook = name      
      this.selectVerse(verse)
    }

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