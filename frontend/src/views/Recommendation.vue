<template>
  <div class="recommendation-page">
    <h1 class="text-3xl font-bold mb-6">智能推荐</h1>
    
    <!-- 推荐选项卡 -->
    <div class="bg-white rounded-lg shadow-md p-6 mb-6">
      <div class="flex space-x-4 mb-6">
        <button 
          @click="currentTab = 'personalized'"
          :class="['px-4 py-2 rounded-md', currentTab === 'personalized' ? 'bg-primary-600 text-white' : 'bg-gray-200']"
        >
          个性化推荐
        </button>
        <button 
          @click="currentTab = 'hot'"
          :class="['px-4 py-2 rounded-md', currentTab === 'hot' ? 'bg-primary-600 text-white' : 'bg-gray-200']"
        >
          热门景点
        </button>
        <button 
          @click="currentTab = 'nearby'"
          :class="['px-4 py-2 rounded-md', currentTab === 'nearby' ? 'bg-primary-600 text-white' : 'bg-gray-200']"
        >
          周边推荐
        </button>
      </div>
      
      <!-- 推荐结果列表 -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div 
          v-for="item in recommendations" 
          :key="item.id"
          class="border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
        >
          <h3 class="font-semibold text-lg mb-2">{{ item.name }}</h3>
          <p class="text-gray-600 text-sm mb-2">{{ item.reason }}</p>
          <div class="flex items-center justify-between">
            <span class="text-yellow-500">⭐ {{ item.rating }}</span>
            <span class="text-primary-600 font-semibold">评分：{{ item.score }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '@/api'

const currentTab = ref('personalized')
const recommendations = ref([])

onMounted(async () => {
  // 加载推荐数据
  try {
    const response = await api.recommendation.getPersonalized({ limit: 10 })
    if (response.code === 200) {
      recommendations.value = response.data.recommendations
    }
  } catch (error) {
    console.error('加载推荐失败:', error)
  }
})
</script>
