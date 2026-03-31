<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <!-- 顶部导航栏 -->
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <h1 class="text-xl font-bold text-primary-600">个性化旅游系统</h1>
            </div>
            <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
              <router-link
                to="/"
                class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                首页
              </router-link>
              <router-link
                to="/recommend"
                class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                智能推荐
              </router-link>
              <router-link
                to="/route"
                class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                路径规划
              </router-link>
              <router-link
                to="/diary"
                class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                游记管理
              </router-link>
            </div>
          </div>
          <div class="flex items-center">
            <button
              v-if="!userStore.isLoggedIn"
              @click="showLogin = true"
              class="bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md text-sm font-medium"
            >
              登录
            </button>
            <div v-else class="flex items-center space-x-4">
              <span class="text-gray-700 text-sm">{{ userStore.username }}</span>
              <button
                @click="handleLogout"
                class="text-gray-500 hover:text-gray-700 text-sm"
              >
                退出
              </button>
            </div>
          </div>
        </div>
      </div>
    </nav>

    <!-- 主内容区 -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <router-view />
    </main>

    <!-- 页脚 -->
    <footer class="bg-white border-t mt-8">
      <div class="max-w-7xl mx-auto px-4 py-6">
        <p class="text-center text-gray-500 text-sm">
          数据结构课程设计 © 2026 - yhm, zby, lxd
        </p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from './store/user'

const router = useRouter()
const userStore = useUserStore()
const showLogin = ref(false)

const handleLogout = () => {
  userStore.logout()
  router.push('/')
}
</script>

<style>
/* 全局样式 */
#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Leaflet 地图容器高度 */
.map-container {
  height: 500px;
  width: 100%;
}
</style>
