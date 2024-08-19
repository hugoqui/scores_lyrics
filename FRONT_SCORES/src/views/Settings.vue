<template>
  <main class="container">
      <div class="row mt-5">
          <div class="col">
              <h1 class="gold">Ajustes</h1>

              <div class="row">
                  <div class="col">
                    <b class="gold">Ruta de Server</b> 
                    <input type="text" class="form-control bg-darker text-warning"  v-model="host">
                    <button style="width:10rem" class="p-3 mt-1 btn btn-outline-warning" @click="setHost()">Guardar Host</button>
                </div>
            </div>
            
            <div class="row mt-3">
                <div class="col gold">
                    <b class="gold">Pantalla de Prompter</b> <br>
                    <button style="width:10rem" class="btn p-3 btn-outline-warning" @click="changePrompterScreen()" >
                        {{ $store.state.isPrompterScreen ? 'activada' : 'desactivada' }}
                    </button>
                </div>
            </div>
            
            <div class="row mt-3">
                <div class="col gold">
                    <b class="gold">Servidor de Prompter</b> <br>
                    <button style="width:10rem" class="btn p-3 btn-outline-warning" @click="changeServer()" >
                        {{ $store.state.isServer ? 'activado' : 'desactivado'}}
                    </button>
                </div>
              </div>
              
              <div class="row mt-3">
                  <div class="col gold">
                    <b class="gold">Control de Prompter</b> <br>
                    <button style="width:10rem" class="btn p-3 btn-outline-warning" @click="changeControl()" >
                        {{ $store.state.isControl ? 'activado' : 'desactivado'}}
                    </button>
                </div>
              </div>
          </div>
      </div>
  </main>
</template>

<script>
export default {
    data(){
        return {
            host:"",
        }
    },
    mounted(){
        this.host = this.$store.state.socketUrl
    },
    methods:{
        setHost(){
            localStorage.setItem("host", this.host)
            this.$store.commit("setHost",this.host)
            window.location.reload()
        },
        changePrompterScreen(){
            const newValue = !this.$store.state.isPrompterScreen 
            this.$store.state.isPrompterScreen = newValue
            localStorage.setItem("isPrompterScreen", newValue)
        },
        changeServer(){
            const newValue = !this.$store.state.isServer 
            this.$store.state.isServer = newValue
            localStorage.setItem("isServer", newValue)
        },
        changeControl(){
            const newValue = !this.$store.state.isControl 
            this.$store.state.isControl = newValue
            localStorage.setItem("isControl", newValue)
        }
    }
}
</script>

<style>

</style>