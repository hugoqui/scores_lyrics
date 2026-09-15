<template>
    <main style="position: relative;">

        <img src="@/assets/pen.png" alt="belen" @click="$emit('edit', song)" class="edit-btn" v-if="showEdit">
        <img src="@/assets/trash.png" alt="belen" @click="$emit('remove', song)" class="delete-btn" v-if="showDelete">
        
        <div class="song-item" :class="type=='gold' ? 'bg-gold dark' : 'bg-darker white'" 
             @click="$emit('selected', song)" 
             @contextmenu.prevent="showContextMenu($event)">
           {{ song.title }}
        </div>
        
    </main>
</template>

<script>
export default {
    props: ["song", "type", "showEdit", "showDelete"],
    data() {
        return {
            menuX: 0,
            menuY: 0,
            showMenu: false,
        }
    },
    methods: {
        showContextMenu(event){
            event.preventDefault();
            this.menuX = event.clientX;
            this.menuY = event.clientY;
            this.showMenu = true;
        }
    },
}
</script>

<style lang="scss" scoped>

.song-item{
    text-transform: capitalize;
    padding: 1rem;
    border-radius: .5rem;    
    padding: 8px;
    font-style: italic;
    font-weight: 600;    
    cursor:pointer;
    height: 6rem;
    margin:0;
    margin-bottom: 1rem;

    -webkit-user-select: none; /* Safari */
    -ms-user-select: none; /* IE 10 and IE 11 */
    user-select: none; 
}

.edit-btn{
    background-color: rgba($color: #000, $alpha: 0.2);
    backdrop-filter: blur(15px);
    border-radius: 4px;
    padding: 5px 8px;
    position: absolute;
    height:24px;
    bottom: 0px;
    right: 0;
    transition: all 300ms;
}

.edit-btn:hover{
    transform:scale(1.1);
}

.delete-btn{
    background-color: rgba($color: #951010, $alpha: 0.6);
    backdrop-filter: blur(15px);
    border-radius: 4px;
    padding: 5px 8px;
    position: absolute;
    height:24px;
    bottom: 0px;
    left: 0;
    transition: all 300ms;
}

.delete-btn:hover{
    transform:scale(1.1);
}

</style>
