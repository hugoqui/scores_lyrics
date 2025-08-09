import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import socket from "./socket";

Vue.config.productionTip = false

let host = localStorage.getItem("host")
if (!host) {
  host = `http://${window.location.hostname}:3014/`
}
store.commit("setHost",host)


let isPrompterScreen = localStorage.getItem("isPrompterScreen")
store.commit("setPrompterScreen", !!isPrompterScreen)

let isServer = localStorage.getItem("isServer")
store.commit("setServer", !!isServer)

let isControl = localStorage.getItem("isControl")
store.commit("setControl", !!isControl)

Vue.prototype.$socket = socket;

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
