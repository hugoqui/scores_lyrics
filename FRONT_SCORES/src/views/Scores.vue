<template>
    <div id="fullscreen">
        <!-- <h5>{{ finalUrl }}</h5> -->
        <button class="btn shadow btn-dark" id="toggleScore" @click="showArragement = !showArragement">
            {{ showArragement ? 'Arreglo' : 'Melodía' }}
        </button>
        <img :src="`${finalUrl}`" class="img-fluid" :alt="title"
            style="max-height:100%; max-width:100%" @error="imageLoadError()" @click="setFullscreen()">
    </div>
</template>

<script>
export default {
    props: ["instrument"],
    sockets: {
        text_change: function (data) {
            console.log("caambiar, el text... ", data.text, !data.text)
            if (!data.text) {
                return
            }

            this.displaySong(data)
        }
    },
    data() {
        return {
            url: "",
            isFullScreen: false,
            title: "",
            extension: ".png",
            count: 0,
            showArragement: false,
        }
    },
    mounted() {
        this.getLast()
    },

    computed: {
        finalUrl() {
            let host = localStorage.getItem("host") || "";
            host = host.replace(/:\d+\/$/, "");
            
            if (this.showArragement && this.count) {
                const instrument = this.instrument.replace(/\/$/, "");
                return host + this.url  + "_" + instrument + this.extension
            }

            return host + this.url  + this.extension
        }
    },

    methods: {
        setFullscreen() {
            if (this.isFullScreen) {
                document.exitFullscreen()
            } else {
                document.documentElement.requestFullscreen()
            }
            this.isFullScreen = !this.isFullScreen
        },

        imageLoadError() {

            if (this.count > 1) {
                return false
            }

            this.count++

        },
        displaySong(data) {
            const lowertext = data.title.toLowerCase()
            const words = lowertext.split(" ")
            let title = ""
            words.forEach(word => {
                title = title + word + "_"
            })
            title = title.substring(0, title.length - 1)
            this.title = title
            this.url = '/panel/img/scores/' + this.instrument + '/' + title

            if (this.showArragement)
                this.url += "_" + this.instrument

            this.count = 1
        },
        async getLast() {
            try {
                let url = this.$store.state.url + "lastSong"
                const req = await fetch(url)
                if (req.ok) {
                    let title = await req.text()
                    title = title.substring(1)
                    title = title.substring(0, title.length - 1)

                    const data = { title: title }
                    this.displaySong(data)
                }
            } catch (error) {
                console.error(error)
            }
        }
    }
}
</script>

<style lang="scss" scoped>
#fullscreen {
    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;
    background: #fff;
    text-align: center;
}

#toggleScore {
    position: fixed;
    z-index: 9999;
    right: 12px;
    padding: 16px 42px;
    bottom: 10px;
}
</style>