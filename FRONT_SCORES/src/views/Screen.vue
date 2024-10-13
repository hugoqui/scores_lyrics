<template>
    <div id="screen-background" @click="fullscreen()" > 
        <div class="text-center animated v-container" :class="classOut">
            <p ref="scriptureText"
                v-show="showVerse"
                class="scripture"
                id="scripture"
                :class="scripture.reference.length == 0 ? 'breaks' :''">
                {{scripture.text}}
                
                <template v-if="scripture.reference && scripture.reference.length > 0">
                    <br>
                    <span class="gold " :style="`font-size:${fontSize * 0.7}px; font-weight: bold;`">{{scripture.reference}}</span>
                </template>
            </p>
        </div>
    </div>
</template>

<script>
export default {
    sockets: {
        connect: function () {
            console.log('socket connected');
        },
        text_change: function (data) {
            this.classOut = "animated-out"
            setTimeout(() => {            
                this.showVerse = false;
                this.classOut = ""            
                this.scripture.text = data.text.trim();
                this.scripture.reference = data.reference;
                this.showVerse = true;

                // Ajustar el tamaño de la fuente después de que el DOM se actualice
                this.$nextTick(() => {
                    this.adjustFontSize();
                });
            }, 300);
        }
    },
    data: () => ({
        scripture: { text: "", reference: "" },
        showVerse: false,
        classOut: "",
        fontSize: 175
    }),
    methods: {
        getStyle(){
            const config = this.$store.state.config.filter(c=> c.module=="screen")
            let result = {}            
            config.forEach(element => {
                result[element.name] = element.value
            });
            console.log("El config de script...", result)
            return result
        },
        adjustFontSize() {
            const el = this.$refs.scriptureText;
            let fontSize = 175; // Tamaño inicial en vw
            el.style.fontSize = `${fontSize}px`;
            const containerHeight = el.parentElement.clientHeight;
            const containerWidth = el.parentElement.clientWidth;
            // Reducir el tamaño de la fuente hasta que el texto no se desborde con margen

            if (this.scripture.reference) {
                while ((el.scrollHeight > containerHeight) && fontSize > 32) {
                    fontSize -= 1;
                    el.style.fontSize = `${fontSize}px`;
                }
            }

            if (!this.scripture.reference) {
                while ((el.scrollHeight > containerHeight || el.scrollWidth > containerWidth) && fontSize > 32) {
                    fontSize -= 1;
                    el.style.fontSize = `${fontSize}px`;
                }                
            }

            this.fontSize = fontSize

            console.log("Final font size: ", fontSize + "px");
        },

        fullscreen(){            
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        },
    }
};
</script>

<style lang="scss" scoped>

#screen-background {    
    background: radial-gradient(circle, #26293a 33%, rgb(11, 10, 21) 90%) !important;   
    // background-color: #151719;
    height: 100vh;
    position: relative;
    padding: 4rem 0;
}

.v-container {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100%;    
}

.scripture {
    font-family: Arial, Helvetica, sans-serif;
    color: #ffffff;
    line-height: normal;
    width: auto;
    text-shadow: 0px 0px 4px #000;
    font-size: 175px;
    padding: 0.5rem 5%;
    box-sizing: border-box;
    text-shadow: 4px 4px 8px rgba($color: #000, $alpha: 0.9);
    font-weight: bold;
}

.breaks {
    white-space: pre;
}

.animated {    
    animation-name: fade-in;
    animation-duration: 500ms;
}

@keyframes fade-in {
    0% { opacity: 0; }        
    100% { opacity: 1; }
}

.animated-out{       
    animation-name: fade-out;
    animation-duration: 500ms;
}

@keyframes fade-out {
    0% { opacity: 1; }        
    100% { opacity: 0; }
}
</style>
