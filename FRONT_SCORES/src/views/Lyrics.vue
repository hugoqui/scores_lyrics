<template>
    <div class="body">
        <div v-if="showVerse" class="text-center animated" style="position:fixed; bottom:1rem; width:100%;">
            <h1 class="scripture"
                style="margin-bottom:1rem; width:100%;  text-shadow: 0px 0px 10px #000; font-size:4.5rem;"
                :class="scripture.reference.length == 0 ? 'breaks' : ''">
                <!-- :style="scripture.text.length > 160 ? 'font-size:3rem;' : 'font-size:4.5rem;'" -->
                {{ scripture.text }}
            </h1>

            <span style="color: yellow; font-size:3.5rem">{{ scripture.reference }}</span>
        </div>
    </div>
</template>

<script>
export default {
    data: () => ({
        scripture: { text: "", reference: "" },
        showVerse: false,
        url: null,
    }),
    mounted() {
        this.url = this.$store.state.url
        this.getLastSong()

        this.$socket.on('connect', () => {
            console.log('socket connected');
        });
        this.$socket.on('text_change', (data) => {
            this.showLyrics(data);
        });

    },
    beforeDestroy() {
        this.$socket.off('connect');
        this.$socket.off('text_change');
    },

    methods: {
        async getLastSong() {
            console.log("obteniendo ultimo canto... ")
            const req = await fetch(this.url + "lastSong")
            const res = await req.json()
            console.log(res)
            this.showLyrics({ text: res, reference: "" })
        },
        showLyrics(data) {
            this.showVerse = false
            setTimeout(() => {
                let text = data.text
                for (let i = 0; i < 10; i++) {
                    text = text.replace("{\\i", '')
                    text = text.replace("{\\i", '')
                    text = text.replace("{\\i", '')
                    text = text.replace("}", '')
                    text = text.replace("}", '')
                    text = text.replace("}", '')
                    text = text.replace("\\par", '')
                    text = text.replace("\\par", '')
                    text = text.replace("\\par", '')
                    text = text.replace("\\par", '')
                    text = text.replace("{\\cf6", '')
                    text = text.replace("{\\cf6", '')
                    text = text.replace("{\\cf6", '')
                    text = text.replace("{", '')
                    text = text.replace("{", '')
                    text = text.replace("{", '')
                    text = text.replace("cf6", '')
                    text = text.replace("cf6", '')
                    text = text.replace("cf6", '')
                    text = text.replace("cf6", '')
                    text = text.replace(`\\`, '')
                    text = text.replace(`\\`, '')
                    text = text.replace(`\\`, '')
                    text = text.replace(`\\`, '')
                }

                this.scripture.text = text.trim();
                this.scripture.reference = data.reference
                this.showVerse = true
            }, 300);
        },

    }
}
</script>
<style lang="scss" scoped>
.body {
    // background: green;
    background: darkblue;
    // padding-left: 10%;    
    // padding-right: 10%;    
    padding-top: 10%;
    height: 100vh;
}

.scripture {
    font-family: "Century Gothic";
    // font-weight: bold;
    color: #ffffff;
}

.breaks {
    white-space: pre;
}


.animated {
    animation-name: example;
    animation-duration: 600ms;
}

@keyframes example {
    0% {
        opacity: 0;
    }

    100% {
        opacity: 1;
    }
}
</style>