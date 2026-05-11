<template>
  <div class="container-fluid mt-4 mb-5">
    <h1 class="text-center mb-5 display-2 gold">Lyrics & Scores</h1>
    <div class="row mt-3">
      <div class="col-md-3 col-sm-6 offset-sm-0 col-6 text-center" v-for="(item,i) in items" :key="i">
        <div class="m-3 shadow p-3 zoom" style="border-radius:1rem; background:rgba(0,0,0,0.3)" @click="$router.push(item.to)">
          <img :src="item.picture" class="img-fluid mt-3 mb-3" style="max-height:200px">
          <h1 class="d-none d-md-block white text-uppercase">{{item.title}}</h1>
          <h5 class="d-block d-md-none white text-uppercase">{{item.title}}</h5>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

export default {

  data: ()=>({
    items:[
      {id:0, title: "Stream", picture: require('@/assets/icons/video.png'), to: "stream"},
      {id:1, title: "Biblia", picture: require('@/assets/icons/bible.png'), to: "bible"},
      {id:2, title: "Cantos", picture: require('@/assets/icons/songs.png'), to: "songs"},
      {id:3, title: "Lyrics", picture: require('@/assets/icons/lyrics.png'), to: "lyrics"},
      {id:3, title: "Proyector", picture: require('@/assets/icons/screen.png'), to: "screen"},      
      {id:12, title: "Prompter", picture: require('@/assets/icons/prompter.png'), to: "prompter"},
      {id:13, title: "Ajustes", picture: require('@/assets/icons/settings.png'), to: "settings"},
    ]    
  }),
  async mounted(){
    this.url = this.$store.state.url
  },
  methods:{


  }
}
</script>

<style >
.zoom{
  cursor: pointer;
  /* animation: zoom 300ms; */
  transition: all 300ms;
}

.zoom:hover{
  transform: scale(1.04);
}
</style>