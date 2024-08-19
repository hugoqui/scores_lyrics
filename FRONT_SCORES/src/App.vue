<template>
  <div id="app">
    <router-view/>
  </div>
</template>

<script>
export default {
  beforeCreate(){
    let host = this.$store.state.url
    
    console.log("el url del host... ", host)
  }
}
</script>


<style lang="scss">
$dark: #343740;
$gold: #FFCD30;
$white: #fff;

body, html{
  background: $dark;
  // scroll-behavior: smooth;
}

.white{color: $white;}
.gold{color: $gold;}
.dark{color: $dark;}

.bg-white{background-color: $white !important;}
.bg-gold{background-color: $gold !important;}
.bg-dark{background-color: $dark !important;}
.bg-darker{background-color: darken($color: $dark, $amount: 5) !important;}


/* width */
::-webkit-scrollbar {
  width: 7px;
}

/* Track */
::-webkit-scrollbar-track {
  // background: #f1f1f1; 
  background: #222; 
}
 
/* Handle */
::-webkit-scrollbar-thumb {
  background: darken($color: $white, $amount: 5); 
  min-height: 3rem;
  border-radius: 10px;
  transition: all 300ms;
}

/* Handle on hover */
::-webkit-scrollbar-thumb:hover {
  background: darken($color: $white, $amount: 20);   
}

.prompter{
  line-height: 110px;
}

.btn:hover, .btn:focus {
  color: lighten($color: $gold, $amount: 10);
}
</style>
