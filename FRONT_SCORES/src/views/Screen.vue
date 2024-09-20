<template>
    <div id="screen-background">
        <div class="text-center animated v-container" :class="classOut">
            <p ref="scriptureText"
                v-show="showVerse"
                class="scripture"
                id="scripture"
                :class="scripture.reference.length == 0 ? 'breaks' :''">
                {{scripture.text}}
                
                <template v-if="scripture.reference && scripture.reference.length > 0">
                    <br>
                    <span class="gold " :style="`font-size:${fontSize * 0.7}vw; font-weight: bold;`">{{scripture.reference}}</span>
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
                let text = data.text.replace("{\\i", '')
                text = text.replace("}", '')
                text = text.replace("\\par", '')
                // text = text.replace("\par", '')
                text = text.replace("\\", '')
                text = text.replace("{", '')
                text = text.replace("cf6", '')
                text = text.replace("{\\cf6", '')

                this.scripture.text = text.trim();
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
        fontSize: 7
    }),
    methods: {
        adjustFontSize() {
            const el = this.$refs.scriptureText;
            let fontSize = 7; // Tamaño inicial en vw
            el.style.fontSize = `${fontSize}vw`;
            const containerHeight = el.parentElement.clientHeight;
            // Reducir el tamaño de la fuente hasta que el texto no se desborde con margen
            // while ((el.scrollHeight > containerHeight || el.scrollWidth > containerWidth) && fontSize > 3) {
            while ((el.scrollHeight > containerHeight) && fontSize > 2) {
                fontSize -= 0.25;
                el.style.fontSize = `${fontSize}vw`;
            }

            this.fontSize = fontSize

            console.log("Final font size: ", fontSize + "vw");
        }
    }
};
</script>

<style lang="scss" scoped>
.body {
    padding-left: 10%;    
    padding-right: 10%;    
    padding-top: 10%;    
    height: 100vh;
}

#screen-background {
    background: rgb(13,81,161);
    background: radial-gradient(circle, rgba(13,81,161,1) 33%, rgba(2,0,36,1) 100%);
    // background: linear-gradient(180deg, rgb(20, 20, 54), rgb(21, 26, 37));
    // background: #113;
}

.v-container {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
}

.scripture {
    font-family: "Montserrat";    
    color: #ffffff;
    width: auto;
    text-shadow: 0px 0px 4px #000;
    font-size: 7vw;
    padding: 0.5rem 5%; /* Añadir un margen interno (padding) del 5% */
    box-sizing: border-box; /* Asegura que el padding esté incluido en el tamaño total */    
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
