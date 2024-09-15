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
                    <span class="gold" style="font-size:2.5rem">{{scripture.reference}}</span>
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
    }),
    methods: {
        adjustFontSize() {
            const el = this.$refs.scriptureText;
            let fontSize = 7; // Tamaño inicial en vw
            el.style.fontSize = `${fontSize}vw`;

            const containerWidth = el.parentElement.clientWidth;
            const containerHeight = el.parentElement.clientHeight;

            // Reducir el tamaño de la fuente hasta que el texto no se desborde con margen
            while ((el.scrollHeight > containerHeight || el.scrollWidth > containerWidth) && fontSize > 3) {
                fontSize -= 0.5;
                el.style.fontSize = `${fontSize}vw`;
            }

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
    background: linear-gradient(45deg, #001, #113);
    // background: #113;
}

.v-container {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
}

.scripture {
    font-family: "Arial";    
    color: #ffffff;
    width: auto;
    text-shadow: 0px 0px 4px #000;
    font-size: 7vw;
    padding: 0 5%; /* Añadir un margen interno (padding) del 5% */
    box-sizing: border-box; /* Asegura que el padding esté incluido en el tamaño total */
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
