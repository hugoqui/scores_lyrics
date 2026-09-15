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
                    <button class="my-2 w-100 btn bg-darker gold p-2 py-5" @click="autoPlay(true)">
                        > Play
                    </button>
                </div>
                <div class="col-6 " v-if="isPlaying">
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
                <h6 class="text-center w-100 gold">{{ step }} salto</h6>

                <input type="range" min="40" max="150" class="w-100 slider mt-2 mb-3" v-model="size"
                    @change="changeSize()">
                <h6 class="text-center w-100 gold">{{ size }} tamaño</h6>
            </div>

        </div>

        <!-- PANTALLA / TABLET -->
        <div v-if="$store.state.isPrompterScreen" class="row mt-2 text-white text-prompter"
            :style="mirror ? 'transform: scaleX(-1)' : 'transform: scaleX(1)'"
            style="white-space: pre-line; width:100%; position: relative;" @click="fullscreen()">


            <button class="btn p-3 bg-darker gold" @click="mirror = !mirror">Rotar {{ mirror }}</button>
            <div class="col-12 p-3 prompter" style="font-weight:bold" :style="'font-size:' + size + 'px'">
                {{ content }}
            </div>
        </div>
    </main>
</template>

<script>
export default {
    data() {
        return {
            console: "log...",
            show: true,
            content: "",
            y: 0,
            size: 80,
            step: 50,
            playInterval: null,
            isPlaying: false,

            mirror: false,
        }
    },
    mounted() {
        this.$socket.on('connect', () => {
            console.log('socket connected');
        });

        this.$socket.on('scroll_down', () => {
            if (!this.$store.state.isPrompterScreen) return;

            this.y = Number(this.y) + Number(this.step);
            window.scrollTo(0, this.y);
        });

        this.$socket.on('scroll_up', () => {
            if (!this.$store.state.isPrompterScreen) return;

            this.y = Number(this.y) - Number(this.step);
            window.scrollTo(0, this.y);
        });

        this.$socket.on('auto_play', (shouldPlay) => {
            console.log("auto play received... ", shouldPlay);
            this.isPlaying = shouldPlay;
            this.console = "auto play... " + shouldPlay;

            if (!shouldPlay) {
                clearInterval(this.playInterval);
                this.playInterval = null;
                return;
            }

            if (!!this.playInterval) {
                console.log("ya existe el intervalo... ", shouldPlay);
                return;
            }

            console.log("creando intervalo... ", shouldPlay);

            this.playInterval = setInterval(() => {
                if (this.y >= document.body.scrollHeight) {
                    console.log("llego el limite... hay que terminarla");
                    clearInterval(this.playInterval);
                    this.playInterval = null;
                }

                if (this.isPlaying) {
                    this.y = Number(this.y) + (this.step / 10);
                    window.scrollTo(0, this.y);
                }
            }, 30);
        });

        this.$socket.on('change_step', (step) => {
            console.log("cambió el step....");
            this.step = Number(step);
        });

        this.$socket.on('change_size', (size) => {
            console.log("cambió el size....");
            this.size = Number(size);
        });

        this.$socket.on('receive_text', (text) => {
            console.log("cambio texto... ");
            this.content = text;
        });

        this.$socket.on('go_top', () => {
            this.reset();
        });
    },
    beforeDestroy() {
        this.$socket.off('connect');
        this.$socket.off('scroll_down');
        this.$socket.off('scroll_up');
        this.$socket.off('auto_play');
        this.$socket.off('change_step');
        this.$socket.off('change_size');
        this.$socket.off('receive_text');
        this.$socket.off('go_top');
    },
    methods: {
        scroll_down() { this.$socket.emit("scroll_down_to_server") },
        scroll_up() { this.$socket.emit("scroll_up_to_server") },
        reset() {
            this.y = 0
            window.scrollTo(0, 0)
        },

        autoPlay(shouldPlay) {
            this.isPlaying = !this.isPlaying
            shouldPlay ? this.$socket.emit("auto_play_on") : this.$socket.emit("auto_play_off")
        },

        changeStep() {
            this.$socket.emit("change_step_server", this.step)
        },

        changeSize() {
            this.$socket.emit("change_size_server", this.size)
        },

        fullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        },

        sendText() {
            this.$socket.emit("send_text_server", this.content)
        },
    },
}
</script>

<style>
#prompter-main {
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

@media screen {}
</style>