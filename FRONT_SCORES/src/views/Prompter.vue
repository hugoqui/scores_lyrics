<template>
  <main class="container-fluid" id="prompter-main">
<!--     
    <div style="position: fixed; top: 30vh; left: 3rem; background-color: #ddd; 
                z-index: 999;">
        {{ console }} <br>
        isPlaying {{ isPlaying }}
    </div> -->

    <!-- SERVER / PC -->
    <div v-if="$store.state.isServer" class="row">
        <div class="col-md-10">
            <textarea cols="30" rows="10" class="form-control" v-model="content" v-if="show"></textarea>
        </div>
        <div class="col">
            <button @click="reset()" class="my-2 w-100 btn bg-darker gold p-3">Reiniciar</button> <br>
            <button @click="sendText()" class="my-2 w-100 btn bg-darker gold p-3">Enviar</button> <br>
        </div>
    </div>

    <!-- CONTROL / MOVIL -->
    <div class="d-sm-block d-md-none" v-if="$store.state.isControl">
    <div class="row mt-5">
        <div class="col-12">
            <button @click="scroll_up()" class="my-2 w-100 btn bg-darker gold p-3" style="height:20vh">
                <h1> Subir </h1>                    
            </button> <br>
        </div>
        <div class="col-12">
            <button @click="scroll_down()" class="my-2 w-100 btn bg-darker gold p-3" style="height:20vh">
                <h1> Bajar </h1>
            </button> <br>
        </div>

        <div class="col-6 " v-if="!isPlaying">
            <button class="my-2 w-100 btn bg-darker gold p-2 py-5" @click="autoPlay(true)" >
                > Play
            </button>
        </div>
        <div class="col-6 "  v-if="isPlaying">
            <button class="my-2 w-100 btn bg-darker gold p-2 py-5" @click="autoPlay(false)">
                || Pause
            </button>
        </div>
        <div class="col-6 ">
            <button class="my-2 w-100 btn bg-darker gold p-2 py-5" @click="$socket.emit('go_top_server')">
                Inicio
            </button>
        </div>
        
        <input type="range" name="" id="" class="w-100 slider mt-5 mb-3" v-model="step" @change="changeStep()">
        <h6 class="text-center w-100 gold">{{step}} salto</h6>

        <input type="range" min="40" max="150" class="w-100 slider mt-2 mb-3" v-model="size" @change="changeSize()">
        <h6 class="text-center w-100 gold">{{size}} tamaño</h6>
    </div>

    </div>

    <!-- PANTALLA / TABLET -->
    <div v-if="$store.state.isPrompterScreen" class="row mt-2 text-white text-prompter" 
                :style=" mirror ? 'transform: scaleX(-1)': 'transform: scaleX(1)' " 
         style="white-space: pre-line; width:100%; position: relative;" @click="fullscreen()">


        <button class="btn p-3 bg-darker gold" @click="mirror = !mirror">Rotar {{ mirror }}</button>
        <div class="col-12 p-3 prompter" style="font-weight:bold" :style="'font-size:' + size+'px'">
        {{content}}           
        </div> 
    </div>
  </main>
</template>

<script>
export default {
    data(){
        return {
            console: "log...", 
            show:true,
            content: "",
            y:0,
            size:80,
            step:50,
            playInterval:null,
            isPlaying:false,

            mirror: false,
        }
    },
    mounted(){

    },
    methods:{
        scroll_down(){this.$socket.emit("scroll_down_to_server")},
        scroll_up(){  this.$socket.emit("scroll_up_to_server")  },
        reset(){
            this.y=0
            window.scrollTo(0,0)
        },

        autoPlay(shouldPlay){
            this.isPlaying = !this.isPlaying
            shouldPlay ? this.$socket.emit("auto_play_on") : this.$socket.emit("auto_play_off")
        },
        
        changeStep(){
            this.$socket.emit("change_step_server", this.step)
        },
        
        changeSize(){
            this.$socket.emit("change_size_server", this.size)
        },

        fullscreen(){            
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        },

        sendText(){
            this.$socket.emit("send_text_server", this.content)
        },
    },
    sockets: {
        connect: function () {
            console.log('socket connected')
        },

        scroll_down: function () {
            if (!this.$store.state.isPrompterScreen) {return}

            this.y = Number(this.y) + Number(this.step)
            window.scrollTo(0,this.y)        
        },

        scroll_up: function () {
            if (!this.$store.state.isPrompterScreen) {return}

            this.y = Number(this.y) - Number(this.step) 
            window.scrollTo(0,this.y)
        },

        auto_play: function (shouldPlay) {
            console.log("auto play received... ", shouldPlay)
            this.isPlaying = shouldPlay
            this.console = "auto play... " + shouldPlay
            // si no es TRUE se borra el intervalo y sale de la función
            if (!shouldPlay) {
                console.log(" shouldplay... ", shouldPlay)
                clearInterval(this.playInterval)
                this.playInterval = null
                return
            }

            // si llega a este punto y el intervalo existe, que salga de la funcion
            // porque el intervalo ya está activo
            if (!!this.playInterval) {
                console.log("ya existe el intervalo... ", shouldPlay)
                return
            }
          
            //si llega a este punto no exite el intervalo, debe crearlo
            console.log("creando intervalo... ", shouldPlay)
            
            this.playInterval = setInterval(() => {                      
                // si llega al borde inferior, terminar el intervalo
                if (this.y >= document.body.scrollHeight  ) {
                    console.log("llego el limite... hay que terminarla")
                    clearInterval(this.playInterval)
                    this.playInterval = null
                }
                
                //dividir en 10 el tamaño seleccionado para salto
                //solo hacerlo si está reproduciéndose
                if (this.isPlaying) {                    
                    this.y = Number(this.y) + (this.step / 10) 
                    window.scrollTo(0,this.y)
                }                
            }, 30);
            
        },

        change_step: function(step){
            console.log("cambió el step....")
            this.step = Number(step)
        },

        change_size: function(size){
            console.log("cambió el size....")
            this.size = Number(size)
        },

        receive_text: function(text){
            console.log("cambio texto... ")
            this.content = text
        },
        
        go_top: function(step){
            this.reset()
        },


    },
}
</script>

<style>
#prompter-main{    
    overflow-x: hidden;
    background-color: #000;

}
.slider {
  -webkit-appearance: none;
  width: 100%;
  height: 35px;
  background: #555;
  outline: none;
  opacity: 0.7;
  -webkit-transition: .2s;
  transition: opacity .2s;
}

.slider:hover {
  opacity: 1;
}

.slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 45px;
  height: 45px;
  background: #FFCD30;
  border-radius: 10%;
  cursor: pointer;
}

.slider::-moz-range-thumb {
  width: 45px;
  height: 45px;
  background: #FFCD30;
  cursor: pointer;
}
@media screen {
    
}
</style>