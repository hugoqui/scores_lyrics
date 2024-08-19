import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Helper from '../views/Helper.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/helper',
    name: 'Helper',
    component: Helper
  },
  {
    path: '/bible',
    name: 'bible',
    component: () => import('../views/Bible.vue')
  },
  {
    path: '/lyrics',
    name: 'lyrics',
    component: () => import('../views/Lyrics.vue')
  },
  {
    path: '/screen',
    name: 'screen',
    component: () => import('../views/Screen.vue')
  },
  {
    path: '/songs',
    name: 'songs',
    component: () => import('../views/Songs.vue')
  },
  {
    path: '/scores/:instrument',
    name: 'scores',
    props:true, 
    component: () => import('../views/Scores.vue')
  },
  {
    path: '/stream',
    name: 'streamControl',
    props:true, 
    component: () => import('../views/Stream.vue')
  },
  {
    path: '/settings',
    name: 'settings',
    props:true, 
    component: () => import('../views/Settings.vue')
  },
  {
    path: '/prompter',
    name: 'prompter',
    props:true, 
    component: () => import('../views/Prompter.vue')
  },
]

const router = new VueRouter({
  mode: 'hash',
  base: process.env.BASE_URL,
  routes
})

export default router
