import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

// 导入 Tailwind CSS
import './index.css'

// 导入 Leaflet CSS
import 'leaflet/dist/leaflet.css'

// 创建 Vue 应用
const app = createApp(App)

// 使用插件
app.use(router)

// 挂载应用
app.mount('#app')
