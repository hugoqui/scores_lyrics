import Vue from "vue";
import Vuex from "vuex";
// const base = require('../../public/js/host.js').base

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    url: "",
    socketUrl: "",
    isPrompterScreen: false,
    isServer: false,
    isControl: false,
    config: [],
    secondServerUrl: "http://192.168.0.181:3014/api/",    
  },
  mutations: {
    setHost(state, data) {
      state.url = data + "api/";
      state.socketUrl = data;
    },
    setSecondHost(state, data) {
      state.secondServerUrl = data;      
    },

    setPrompterScreen(state, data) {
      state.isPrompterScreen = data;
    },

    setServer(state, data) {
      state.isServer = data;
    },
    setControl(state, data) {
      state.isControl = data;
    },
    setConfig(state, data) {
      state.config = data;
    },
  },
  actions: {
    showVerse( {state}, data) {
      
      const postData = (url) => {
        const opts = { method: "post", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data),};        
        fetch(url, opts);
      }

      postData(state.url + "setNewSong")
      postData(state.secondServerUrl + "setNewSong")
    },
  },
  modules: {},
});
