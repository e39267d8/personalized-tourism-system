import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

// 导入 Leaflet CSS（已经在 index.html 引入）
import 'leaflet/dist/leaflet.css'

// 创建 Vue 应用
const app = createApp(App)

// 创建 Pinia 状态管理
const pinia = createPinia()

// 使用插件
app.use(pinia)
app.use(router)

// 挂载应用
app.mount('#app')
