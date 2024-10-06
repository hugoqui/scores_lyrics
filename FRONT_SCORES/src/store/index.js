import Vue from 'vue'
import Vuex from 'vuex'
// const base = require('../../public/js/host.js').base


Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    url: "",
    socketUrl: "" ,
    isPrompterScreen: false,
    isServer:false,
    isControl:false,
    config:[],
  },
  mutations: {
    setHost(state, data){
      state.url = data + "api/"
      state.socketUrl = data
    },

    setPrompterScreen(state, data){
      state.isPrompterScreen = data
    },

    setServer(state, data){
      state.isServer = data
    },
    setControl(state, data){
      state.isControl = data
    },
    setConfig(state, data){
      state.config = data
    }
  },
  actions: {
  },
  modules: {
  }
})
