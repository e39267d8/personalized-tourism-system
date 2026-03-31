<template>
  <div class="route-plan-page">
    <h1 class="text-3xl font-bold mb-6">路径规划</h1>
    
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- 左侧：输入表单 -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-semibold mb-4">规划选项</h2>
        
        <!-- 起点和终点 -->
        <div class="space-y-4 mb-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">起点</label>
            <input 
              v-model="startPoint"
              type="text" 
              placeholder="输入起点或点击地图选择"
              class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">终点</label>
            <input 
              v-model="endPoint"
              type="text" 
              placeholder="输入终点或点击地图选择"
              class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
        </div>
        
        <!-- 交通方式选择 -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">交通方式</label>
          <div class="flex space-x-4">
            <label class="flex items-center">
              <input type="radio" v-model="transportMode" value="walk" class="mr-2">
              <span>步行</span>
            </label>
            <label class="flex items-center">
              <input type="radio" v-model="transportMode" value="bike" class="mr-2">
              <span>自行车</span>
            </label>
            <label class="flex items-center">
              <input type="radio" v-model="transportMode" value="car" class="mr-2">
              <span>自驾</span>
            </label>
            <label class="flex items-center">
              <input type="radio" v-model="transportMode" value="bus" class="mr-2">
              <span>公交</span>
            </label>
          </div>
        </div>
        
        <!-- 优化目标 -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">优化目标</label>
          <select 
            v-model="optimization"
            class="w-full border rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
          >
            <option value="time">时间最短</option>
            <option value="distance">距离最短</option>
            <option value="balanced">平衡</option>
          </select>
        </div>
        
        <!-- 规划按钮 -->
        <button 
          @click="planRoute"
          class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-md transition-colors"
        >
          开始规划
        </button>
        
        <!-- 规划结果 -->
        <div v-if="routeResult" class="mt-6 p-4 bg-gray-50 rounded-md">
          <h3 class="font-semibold mb-2">规划结果</h3>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span>总距离：</span>
              <span class="font-semibold">{{ (routeResult.total_distance / 1000).toFixed(2) }} km</span>
            </div>
            <div class="flex justify-between">
              <span>预计时间：</span>
              <span class="font-semibold">{{ Math.round(routeResult.total_duration / 60) }} 分钟</span>
            </div>
            <div class="flex justify-between">
              <span>交通方式：</span>
              <span class="font-semibold">{{ transportModeText }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 右侧：地图 -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-semibold mb-4">地图</h2>
        <div ref="mapContainer" class="w-full h-[500px] rounded-lg border"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import L from 'leaflet'
import api from '@/api'

const startPoint = ref('')
const endPoint = ref('')
const transportMode = ref('walk')
const optimization = ref('time')
const routeResult = ref(null)
const mapContainer = ref(null)

let map = null

const transportModeText = computed(() => {
  const modes = {
    walk: '步行',
    bike: '自行车',
    car: '自驾',
    bus: '公交'
  }
  return modes[transportMode.value]
})

onMounted(() => {
  // 初始化地图
  map = L.map(mapContainer.value).setView([39.916, 116.397], 13)
  
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors'
  }).addTo(map)
})

const planRoute = async () => {
  if (!startPoint.value || !endPoint.value) {
    alert('请输入起点和终点')
    return
  }
  
  try {
    // TODO: 实际应该将地址转换为坐标
    const response = await api.route.plan({
      waypoints: [
        { name: startPoint.value },
        { name: endPoint.value }
      ],
      transport_mode: transportMode.value,
      optimization: optimization.value
    })
    
    if (response.code === 200) {
      routeResult.value = response.data
      // 在地图上绘制路径
      drawRoute(response.data.geometry)
    }
  } catch (error) {
    console.error('路径规划失败:', error)
    alert('路径规划失败，请稍后重试')
  }
}

const drawRoute = (geometry) => {
  // TODO: 解析并绘制路径
  console.log('绘制路径:', geometry)
}
</script>
