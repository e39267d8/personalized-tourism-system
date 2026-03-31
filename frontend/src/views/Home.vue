<template>
  <div class="home">
    <!-- 欢迎横幅 -->
    <div class="bg-gradient-to-r from-primary-600 to-primary-800 rounded-lg shadow-lg p-8 mb-8 text-white">
      <h1 class="text-3xl font-bold mb-2">欢迎使用个性化旅游系统</h1>
      <p class="text-primary-100">数据结构课程设计 - 智能旅游全生命周期管理</p>
    </div>

    <!-- 功能卡片 -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
      <!-- 智能推荐 -->
      <div 
        @click="$router.push('/recommend')"
        class="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center mb-4">
          <div class="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mr-4">
            <span class="text-2xl">🎯</span>
          </div>
          <h3 class="text-xl font-semibold">智能推荐</h3>
        </div>
        <p class="text-gray-600">
          基于您的偏好和历史记录，智能推荐最适合的景点。支持 Top-K 排序、多维度匹配。
        </p>
      </div>

      <!-- 路径规划 -->
      <div 
        @click="$router.push('/route')"
        class="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center mb-4">
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mr-4">
            <span class="text-2xl">🗺️</span>
          </div>
          <h3 class="text-xl font-semibold">路径规划</h3>
        </div>
        <p class="text-gray-600">
          基于 Dijkstra 算法的最短路径规划，支持多交通工具、动态拥挤度、多点途经。
        </p>
      </div>

      <!-- 游记管理 -->
      <div 
        @click="$router.push('/diary')"
        class="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center mb-4">
          <div class="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center mr-4">
            <span class="text-2xl">📝</span>
          </div>
          <h3 class="text-xl font-semibold">游记管理</h3>
        </div>
        <p class="text-gray-600">
          记录旅行点滴，支持全文检索、AI 辅助写作、多媒体内容生成。
        </p>
      </div>
    </div>

    <!-- 地图展示 -->
    <div class="bg-white rounded-lg shadow-md p-6 mb-8">
      <h2 class="text-2xl font-semibold mb-4">景点地图</h2>
      <div class="map-container rounded-lg overflow-hidden border">
        <div ref="mapContainer" class="w-full h-full"></div>
      </div>
    </div>

    <!-- 热门景点 -->
    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-2xl font-semibold mb-4">热门景点</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div 
          v-for="spot in hotSpots" 
          :key="spot.id"
          class="border rounded-lg overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
          @click="viewSpotDetail(spot.id)"
        >
          <img :src="spot.image" :alt="spot.name" class="w-full h-40 object-cover">
          <div class="p-4">
            <h3 class="font-semibold mb-2">{{ spot.name }}</h3>
            <div class="flex items-center justify-between text-sm">
              <span class="text-yellow-500">⭐ {{ spot.rating }}</span>
              <span class="text-gray-500">{{ spot.review_count }}条评价</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import L from 'leaflet'

const mapContainer = ref(null)
const hotSpots = ref([
  { id: 1, name: '故宫博物院', rating: 4.8, review_count: 15000, image: 'https://via.placeholder.com/400x200?text=故宫' },
  { id: 2, name: '长城', rating: 4.9, review_count: 20000, image: 'https://via.placeholder.com/400x200?text=长城' },
  { id: 3, name: '颐和园', rating: 4.7, review_count: 12000, image: 'https://via.placeholder.com/400x200?text=颐和园' }
])

// 初始化地图
let map = null

onMounted(async () => {
  // 初始化 Leaflet 地图
  map = L.map(mapContainer.value).setView([39.916, 116.397], 13)
  
  // 添加底图
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors'
  }).addTo(map)
  
  // 加载景点数据（示例）
  const spots = [
    { id: 1, name: '故宫博物院', lat: 39.916, lng: 116.397 },
    { id: 2, name: '天安门广场', lat: 39.908, lng: 116.397 },
    { id: 3, name: '景山公园', lat: 39.922, lng: 116.395 }
  ]
  
  // 添加标记
  spots.forEach(spot => {
    L.marker([spot.lat, spot.lng])
      .addTo(map)
      .bindPopup(`<b>${spot.name}</b>`)
  })
})

const viewSpotDetail = (id) => {
  console.log('View spot detail:', id)
  // TODO: 实现景点详情查看
}
</script>

<style scoped>
.home {
  max-width: 100%;
}
</style>
