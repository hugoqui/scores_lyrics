<template>
    <div id="fullscreen"> 
        <!-- <h5>{{ count }}</h5> -->
        <button class="btn shadow btn-dark" id="toggleScore" @click="showArragement = !showArragement; getFinalUrl()">
            {{ showArragement ? 'Arreglo' : 'Melodía' }}
        </button>
        <img :src="`${finalUrl}`" class="img-fluid" :alt="title" v-if="finalUrl"
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
            finalUrl: null,
        }
    },
    mounted() {
        this.getLast()
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
            console.log("al parecer no existe.. ", this.url)
            if (this.count > 1) {
                return false
            }

            this.count++
            this.getFinalUrl()
        },

        getFinalUrl() {
            console.log("getting final url...")

            let host = localStorage.getItem("host") || "";
            host = host.replace(/:\d+\/$/, "");
            
            if (this.showArragement && this.count == 1) {
                console.log("a ver... con arreglo?")
                const instrument = this.instrument.replace(/\/$/, "");
                this.finalUrl = host + this.url  + "_" + instrument + this.extension
                return
            }
                        
            console.log("pos sin arreglo")            
            console.log("url... ", this.url)

            const appName = this.url.indexOf("panel") != -1 ? "" : "/panel/" 

            this.finalUrl = host + appName + this.url  + this.extension
            return
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
            if (this.url.indexOf("panel") == -1)  {this.url += "/panel"}

            this.url = '/img/scores/' + this.instrument + '/' + title

            // if (this.showArragement)
            //     this.url += "_" + this.instrument
            
            this.count = 1
            this.getFinalUrl()
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
    padding: 16px 42px;
    top: 4px;
    right: 4px;
}
</style>