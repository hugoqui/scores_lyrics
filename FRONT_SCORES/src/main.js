import Vue from 'vue'
import App from './App.vue'
import './registerServiceWorker'
import router from './router'
import store from './store'

Vue.config.productionTip = false


let host = localStorage.getItem("host")
if (!host) {
  host = "http://192.168.0.181:3014/"
}
store.commit("setHost",host)


let isPrompterScreen = localStorage.getItem("isPrompterScreen")
store.commit("setPrompterScreen", !!isPrompterScreen)

let isServer = localStorage.getItem("isServer")
store.commit("setServer", !!isServer)

let isControl = localStorage.getItem("isControl")
store.commit("setControl", !!isControl)

import VueSocketIO from 'vue-socket.io'
Vue.use(new VueSocketIO({
  debug: true,
  connection: store.state.socketUrl,
  vuex: {
    store,
    actionPrefix: 'SOCKET_',
    mutationPrefix: 'SOCKET_'
  },
}))

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
