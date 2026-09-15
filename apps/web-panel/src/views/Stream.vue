<template>
  <div class="container-fluid no-selectable">
    <!-- <h1 class="text-center mb-2 display-2 gold">Stream Control</h1> -->
    <div class="row" style="margin-top: 7rem;" >
      <div class="col-lg-3 col-sm-3 offset-sm-0 col-4 offset-0 text-center" v-for="(item,i) in items.filter(e=> e.pos==='grid')" :key="i">
        <div class="m-1 mt-3 shadow p-2 zoom" style="border-radius:4px; height:5rem; "
              :style="{'background': item.bg || 'rgba(0,0,0,0.3)'}" @click="stream(item.action)">
          
          <h4 class="d-none d-sm-block-none d-md-block d-lg-block white text-uppercase" >{{item.name}}</h4>
          <span style="font-size:14px; font-weight:bold;" 
                class="d-block d-sm-block d-md-none  text-uppercase" 
                :class="item.bg==='#ddd'?'text-black':'white'">
            {{item.name}}
          </span>
          <!-- <img v-if="item.picture !=''" height="100%" :src="item.picture" > -->
          <!--               @/assets/icons/violin1.png -->
          
        </div>
      </div>
    </div>

    <div style="position:fixed; bottom:0; left:0; width:100%; height:6rem; background:#222">
      <div class="row mx-1">
        <div class="col p-1" v-for="(item,i) in items.filter(e=> e.pos==='dock-bottom')" :key="i">
          <div class="mt-2 pt-3 shadow zoom text-center" style="border-radius:4rem; height:4rem; "
                :style="{'background': item.bg || 'rgba(0,0,0,0.3)'}" @click="stream(item.action)">
            
            <h4 class="d-none d-sm-block-none d-md-block d-lg-block white text-uppercase" >{{item.name}}</h4>
            <span style="font-size:20px; font-weight:bold;" class="d-block d-sm-block d-md-none white text-uppercase">
              {{item.name}}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div style="position:fixed; top:0; left:0; width:100%; height:6rem; background:#888">
      <div class="row mx-1">
        <div class="col p-1" v-for="(item,i) in items.filter(e=> e.pos==='dock-top')" :key="i">
          <div class="mt-2 pt-3 shadow zoom text-center" style="border-radius:4rem; height:4rem; "
                :style="{'background': item.bg || 'rgba(0,0,0,0.3)'}" @click="stream(item.action)">
            
            <h4 class="d-none d-sm-block-none d-md-block d-lg-block white text-uppercase" >{{item.name}}</h4>
            <span style="font-size:20px; font-weight:bold;" class="d-block d-sm-block d-md-none white text-uppercase">
              {{item.name}}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

export default {

  data: ()=>({
    items:[
      // {pos: "grid", id:1, action: "1",   name: "REC", bg: "#ff0000"},
      // {pos: "grid", id:2, action: "2",   name: "Pausa", bg: "#deb602"},
      
      {picture:"", pos: "dock-top", id:3, action: "3",   name: "Ly" },
      {picture:"", pos: "dock-top", id:4, action: "4",   name: "Nt" },
      
      {picture:"", pos: "grid", id:5, action: "5",   name: "Intro", bg: "#ddd" },
      {picture:"", pos: "grid", id:6, action: "6",   name: "Escena 1", bg: "#ddd" },
      {picture:"", pos: "grid", id:7, action: "7",   name: "Escena 2", bg: "#ddd" },
      {picture:"", pos: "grid", id:8, action: "8",   name: "Outro", bg: "#ddd" },
      {picture:require("@/assets/icons/pulpito.png"), pos: "grid", id:9, action: "9",   name: "Camara Púlpito" },
      // {picture:"", pos: "grid", id:10, action: "q",   name: "Camara Templo" },
      {picture:"", pos: "grid", id:11, action: "w",   name: "Templo Frontal" },
      {picture:require("@/assets/icons/violin1.png"), pos: "grid", id:11, action: "e",   name: "Violines" },
      {picture:require("@/assets/icons/flute.png"), pos: "grid", id:11, action: "a",   name: "Flautas" },
      {picture:"", pos: "grid", id:12, action: "s",   name: "Camara Fondo" },

      {picture:"", pos: "dock-top", id:13, action: "r",   name: "Tl" },
      {picture:"", pos: "dock-top", id:14, action: "t",   name: "Pr" },

      {picture:"", pos: "dock-bottom", id:15, action: "y", name: "T", bg: "#000077"},
      {picture:"", pos: "dock-bottom", id:16, action: "u", name: "L", bg: "#000077" },
      {picture:"", pos: "dock-bottom", id:17, action: "i", name: "Z", bg: "#007700" },
      {picture:"", pos: "dock-bottom", id:18, action: "o", name: "X" , bg: "#007700"},
      {picture:"", pos: "dock-bottom", id:19, action: "p", name: "N" , bg: "#000"},
    ]    
  }),
  async mounted(){
    this.url = this.$store.state.url
  },
  methods:{
    stream(action){
      this.$socket.emit("streamActionToServer", action)
    }

  }
}
</script>

<style >

</style>