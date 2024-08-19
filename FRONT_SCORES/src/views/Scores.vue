<template>
  <div id="fullscreen" @click="setFullscreen()">      
      <img :src="url+extension" class="img-fluid" :alt="title" style="max-height:100%; max-width:100%" @error="imageLoadError()"  @click="setFullscreen()">
  </div>
</template>

<script>
export default {
    props:["instrument"],
    sockets: {
        text_change: function (data) {
            this.displaySong(data)
        }
    },
    data(){
        return {
            url:"",
            isFullScreen:false,
            title:"",
            extension: ".png",
            count:0,
        }
    },
    mounted(){
        this.getLast()
    },
    methods:{
        setFullscreen(){
            if (this.isFullScreen) {                
                document.exitFullscreen()
            }else {
                document.documentElement.requestFullscreen()
            }
            this.isFullScreen = !this.isFullScreen
        },
        imageLoadError(){            
            if (this.count > 2) {
                return false
            }

            if (this.extension == ".png") {               
                this.extension = ".svg"                
            } else {                
                this.extension = ".png"
            }
            this.count++
            
        },
        displaySong(data){
            const lowertext = data.title.toLowerCase()
            const words = lowertext.split(" ")
            let title = ""
            words.forEach(word => {
                title = title + word + "_"
            })
            title = title.substring(0, title.length-1)
            this.title = title            
            this.url = '/panel/img/scores/'+this.instrument+'/'+title
            this.count = 1
        },
        async getLast(){
            try {
                let url = this.$store.state.url + "lastSong"
                const req = await fetch(url)
                if (req.ok) {
                    let title = await req.text()
                    title = title.substring(1)
                    title = title.substring(0, title.length-1)

                    const data  = {title: title}
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
#fullscreen{
    position: absolute;
    top:0;bottom: 0; left: 0; right: 0;    
    background: #fff;
    text-align: center;
}

</style>