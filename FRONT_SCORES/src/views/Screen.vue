<template>
    <div style="background:#007">
        <div v-if="showVerse" class="text-center animated v-container">
            <p 
                class="scripture " id="scripture"
                :class="scripture.reference.length == 0 ? 'breaks' :''">
                {{scripture.text}}
                
                <br>
                <span v-if="scripture.reference && scripture.reference.length > 0" class="gold" style="font-size:2.5rem">{{scripture.reference}}</span>
            </p>
        </div>
    </div>
</template>

<script>
export default {
sockets: {
    connect: function () {
        console.log('socket connected')
    },
    text_change: function (data) {
        this.showVerse=false
        setTimeout(() => {            
            let text = data.text.replace("{\\i", '')
            text = text.replace("}", '')
            text = text.replace("\\par", '')
            text = text.replace("\par", '')
            text = text.replace("\\", '')
            text = text.replace("{", '')
            text = text.replace("cf6", '')
            text = text.replace("{\\cf6", '')

            this.scripture.text = text
            this.scripture.reference = data.reference
            this.showVerse=true
        }, 300);

        setTimeout(() => {         
            const w = document.getElementById("scripture").clientWidth
            const winW = window.innerWidth
    
            const percentage = w * 100 / winW
            console.log(winW)
            console.log(w)
            console.log(percentage)

            if (percentage > 95) {
                console.log("reducing")
                setTimeout(() => {                    
                    document.getElementById("scripture").style.fontSize="3vw"
                }, 300);
            }

        }, 500);
    }
},
data:()=>({
    scripture:{text:"", reference:""},
    showVerse:false,
})
}
</script>
<style lang="scss" scoped>
.body{
    background: rgb(26, 0, 51);
    padding-left: 10%;    
    padding-right: 10%;    
    padding-top: 10%;    
    height: 100vh;
}

.v-container{
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

.scripture{
    font-family: "Century Gothic";
    font-weight: bold;    
    color: #ffffff;
    width: 90vw;
    text-shadow: 0px 0px 4px #000;

    font-size: 16px;
    font-size: 4vw;
}

.reduce1{
    font-size: 3.5vw;
}

.breaks{
    white-space: pre;
}


.animated{    
    animation-name: example;
    animation-duration: 600ms;
}

@keyframes example {
    0%   {opacity:0;}        
    100% {opacity:1;}
}
</style>