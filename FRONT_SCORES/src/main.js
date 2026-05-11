import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import { initSocket } from "./socket"; // Importa la función, no la instancia

Vue.config.productionTip = false

// 1. Determinar el host primero
let host = localStorage.getItem("host")
if (!host) {
  host = `http://${window.location.hostname}:3014/`
  localStorage.setItem("host", host) // Guárdalo para que socket.js lo vea
}
store.commit("setHost", host)

// 2. Inicializar el socket con el host correcto
const socketInstance = initSocket(host);
Vue.prototype.$socket = socketInstance;

let isPrompterScreen = localStorage.getItem("isPrompterScreen")
store.commit("setPrompterScreen", !!isPrompterScreen)

let isServer = localStorage.getItem("isServer")
store.commit("setServer", !!isServer)

let isControl = localStorage.getItem("isControl")
store.commit("setControl", !!isControl)

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')